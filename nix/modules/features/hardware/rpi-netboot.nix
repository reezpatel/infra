# Netbooted Raspberry Pi client: firmware/kernel over TFTP from the netboot
# server, root on an iSCSI LUN attached in the (systemd) initrd with
# iscsistart. Upstream NixOS has no first-class initrd iSCSI support, so this
# wires the pieces together: network in initrd + iscsi_tcp + a oneshot unit
# ordered before initrd-root-device.target.
{
  ...
}: {
  flake.modules.nixos.rpi-netboot = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.netboot = {
      serverIp = lib.mkOption {
        type = lib.types.str;
        description = "iSCSI/TFTP server (the netboot-server host).";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3260;
      };
      initiator = lib.mkOption {
        type = lib.types.str;
        description = "Initiator IQN; must match the node ACL on the LIO target.";
      };
      targetName = lib.mkOption {
        type = lib.types.str;
        description = "Target IQN on the LIO server.";
      };
      rootLabel = lib.mkOption {
        type = lib.types.str;
        default = "NIXOS_ISCSI";
        description = "Filesystem label of the iSCSI LUN root partition.";
      };

      # Boards where u-boot's Ethernet driver is broken (e.g. flaky genet
      # PHY init) can still join the fleet: the Pi firmware boots the
      # kernel directly from a small FAT "FIRMWARE" partition on an SD
      # card (firmware-direct boot handles large kernels from SD), and
      # only the root filesystem comes from iSCSI as usual.
      sdBoot = {
        enable = lib.mkEnableOption "boot the kernel from an SD FAT partition instead of TFTP/u-boot (root stays on iSCSI)";

        firmwarePackage = lib.mkOption {
          type = lib.types.package;
          default = pkgs.raspberrypifw;
          defaultText = "pkgs.raspberrypifw";
          description = "Package providing start4.elf/fixup4.dat for the boot partition.";
        };

        device = lib.mkOption {
          type = lib.types.str;
          default = "/dev/disk/by-label/FIRMWARE";
          description = "The FAT boot partition (label it FIRMWARE when imaging the SD).";
        };
      };
    };

    config = let
      cfg = config.netboot;
    in {
      # No local boot media at all — firmware is fetched over TFTP.
      boot.loader.systemd-boot.enable = lib.mkDefault false;
      boot.loader.grub.enable = lib.mkDefault false;
      boot.loader.generic-extlinux-compatible.enable = lib.mkDefault false;

      # Mainline kernel (same as the SD fleet): fully substitutable from
      # cache; the vendor rpi4 kernel would compile from source on the
      # x86_64 build host. Its dtbs ship with the kernel; the netboot
      # server prefers the kernel dtb over the firmware one.
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

      boot.kernelParams = [
        "console=serial0,115200"
        "console=tty1"
        "ip=dhcp"
        "root=/dev/disk/by-label/${cfg.rootLabel}"
        "rootwait"
      ];

      boot.initrd.network.enable = true;

      boot.initrd.availableKernelModules = [
        "genet" # Pi 4 GbE (renamed from bcmgenet in mainline 6.18)
      ];

      # Nothing udev-triggers iSCSI modules, so they must be loaded
      # unconditionally in the initrd before iscsistart runs.
      boot.initrd.kernelModules = [
        "iscsi_tcp"
        "libiscsi"
        "libiscsi_tcp"
        "scsi_transport_iscsi"
        "sd_mod"
      ];

      boot.initrd.systemd = {
        enable = true;
        storePaths = [
          "${pkgs.openiscsi}"
        ];
        units."iscsi-root.service" = {
          # Attach the root LUN before the root device is expected to exist.
          # wantedBy generates initrd-root-device.target.wants/iscsi-root.service
          # (a drop-in under /etc/systemd/system is impossible: that path is a
          # read-only symlink into the store inside the initrd).
          wantedBy = ["initrd-root-device.target"];
          text = ''
            [Unit]
            Description=Attach iSCSI root LUN (${cfg.targetName})
            Documentation=man:iscsistart(8)
            DefaultDependencies=no
            After=systemd-networkd-wait-online.service
            Wants=systemd-networkd-wait-online.service
            Before=initrd-root-device.target
            # Never give up restarting: after a site-wide power cut the iSCSI
            # target host boots slower than the Pis, so the first logins fail.
            StartLimitIntervalSec=0

            [Service]
            Type=oneshot
            RemainAfterExit=yes
            Restart=on-failure
            RestartSec=10s
            TimeoutStartSec=0
            # Drop any half-dead session before (re-)logging in, else a retry
            # can wedge forever on "session exists" (ISCSI_ERR_ISID_EXISTS).
            ExecStartPre=-${pkgs.openiscsi}/bin/iscsiadm -m node -T ${cfg.targetName} -p ${cfg.serverIp}:${toString cfg.port} -u
            ExecStart=${pkgs.openiscsi}/bin/iscsistart -i ${cfg.initiator} -t ${cfg.targetName} -a ${cfg.serverIp} -p ${toString cfg.port} -g 1
          '';
        };
      };

      fileSystems =
        {
          "/" = {
            device = "/dev/disk/by-label/${cfg.rootLabel}";
            fsType = "ext4";
          };
        }
        // (lib.optionalAttrs cfg.sdBoot.enable {
          # --- SD-kernel boot variant -----------------------------------------
          "/boot/firmware" = {
            device = cfg.sdBoot.device;
            fsType = "vfat";
            neededForBoot = true;
          };
        });

      systemd.services = lib.mkIf cfg.sdBoot.enable {
        # Syncs kernel/initrd/cmdline from the RUNNING closure to the SD.
        # Runs at boot (ExecStart) and at shutdown/reboot (ExecStop), so a
        # `nixos-rebuild switch` followed by a reboot writes the new kernel
        # to the SD before the machine goes down. Reading /run/current-system
        # (not config.system.build.toplevel) avoids infinite recursion.
        boot-sd-sync = {
          description = "Sync kernel/initrd/firmware to the SD boot partition";
          wantedBy = ["multi-user.target"];
          before = ["shutdown.target" "reboot.target"];
          after = ["local-fs.target"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          path = with pkgs; [coreutils findutils];

          script = let
            fw = cfg.sdBoot.firmwarePackage;
          in ''
            set -euo pipefail
            dst=/boot/firmware
            tl=/run/current-system
            [ -f "$tl/kernel" ] || { echo "no running closure at $tl" >&2; exit 0; }
            for f in start4.elf fixup4.dat bcm2711-rpi-4-b.dtb; do
              src="$(find ${fw} -maxdepth 4 -name "$f" -print -quit)"
              [ -n "$src" ] || { echo "firmware missing $f" >&2; exit 1; }
              install -m 0644 "$src" "$dst/$f"
            done
            install -m 0644 "$tl/kernel" "$dst/kernel8.img"
            install -m 0644 "$tl/initrd" "$dst/initrd"
            cat > "$dst/config.txt" <<'EOF'
            arm_64bit=1
            kernel=kernel8.img
            initramfs initrd followkernel
            dtb=bcm2711-rpi-4-b.dtb
            enable_uart=1
            EOF
            printf '%s\n' "$(cat "$tl/kernel-params") init=$tl/init systemConfig=$tl" > "$dst/cmdline.txt"
            echo "SD boot partition synced."
          '';
        };
      };
    };
  };
}
