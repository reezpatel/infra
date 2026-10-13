# Raspberry Pi fleet netboot server: PXE-proxy DHCP + TFTP + LIO iSCSI root.
#
# Boot files are PUSHED by the Pis themselves (see the `netboot.push` side of
# the rpi-netboot aspect): after every nixos-rebuild and every boot, each node
# uploads its own kernel/initrd/dtb + pxelinux entry (or cmdline.txt for
# firmware-direct boards) over SSH as the `netboot-push` user. This module
# only serves the static baseline:
#
#   /workspace/tftpboot/            start4.elf, fixup4.dat, dtb, config.txt,
#                                   kernel8.img (u-boot)   — all shared
#   /workspace/tftpboot/COMMON/     firmware copies
#   /workspace/tftpboot/<serial>/   per-node dir, OWNED by netboot-push;
#                                   for firmwareBoot nodes the sync also
#                                   seeds the firmware blobs + config.txt
#   /workspace/tftpboot/pxelinux.cfg/
#                                   default = park menu (root-owned);
#                                   01-<mac> pre-created, netboot-push-owned
#
# scripts/netboot-install-lun.sh seeds a node's boot files server-side from
# the same closure it installs, so first boots work before the node has ever
# pushed anything.
{
  ...
}: {
  flake.modules.nixos.netboot-server = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.netboot-server = {
      enable = lib.mkEnableOption "Raspberry Pi network boot server (dnsmasq PXE-proxy + TFTP + iSCSI)";

      interface = lib.mkOption {
        type = lib.types.str;
        description = "LAN interface dnsmasq listens on (e.g. \"eno1\").";
      };

      serverIp = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "This server's LAN IP, advertised to PXE/u-boot clients as the TFTP server (DHCP option 66/150 and next-server).";
      };

      subnet = lib.mkOption {
        type = lib.types.str;
        default = "192.168.2.0";
        description = "LAN subnet for proxy-DHCP (no IPs are leased; the existing DHCP server stays authoritative).";
      };

      tftpRoot = lib.mkOption {
        type = lib.types.str;
        default = "/workspace/tftpboot";
        description = "TFTP root, also where the sync service writes boot trees.";
      };

      firmware = lib.mkOption {
        type = lib.types.package;
        default = pkgs.raspberrypifw;
        defaultText = "pkgs.raspberrypifw";
        description = "Package providing the Pi firmware blobs (start4.elf, fixup4.dat, dtbs).";
      };

      uboot = lib.mkOption {
        type = lib.types.package;
        description = "U-Boot served to the firmware as kernel8.img; it PXE-boots the real kernels.";
      };

      dtbName = lib.mkOption {
        type = lib.types.str;
        default = "bcm2711-rpi-4-b.dtb";
        description = "Device tree to serve (Pi 4 Model B).";
      };

      pushAuthorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "SSH keys authorized for the netboot-push user (fleet nodes push their boot files with these).";
      };

      nodes = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              description = "Node name (nixosConfiguration attr), used for logs.";
            };
            serial = lib.mkOption {
              type = lib.types.str;
              description = "Last 8 digits of the Pi serial (/proc/cpuinfo), used as the node's TFTP directory.";
            };
            mac = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Pi ethernet MAC (lowercase, colon-separated). When set, pxelinux.cfg/01-<mac> is pre-created (netboot-push-owned) so the node can push its own boot menu.";
            };
            iqn = lib.mkOption {
              type = lib.types.str;
              description = "Initiator IQN of the node (must match its LIO ACL). Only informational here.";
            };
            firmwareBoot = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                This node boots firmware-direct (no u-boot): the sync seeds
                its serial dir with the full firmware set + a static
                config.txt; the node itself pushes kernel8.img/initrd/dtb/
                cmdline.txt. The initrd gets an explicit load address in
                config.txt: `followkernel` computes its position from the
                kernel PE header's oversized image_size, which pushes it out
                of reach on mainline kernels.
              '';
            };
          };
        });
        default = [];
        description = "Fleet nodes served by this netboot server.";
      };
    };

    config = let
      serverIp =
        if config.netboot-server.serverIp != null
        then config.netboot-server.serverIp
        else "";
      # PXE-only u-boot: stock distro boot tries mmc/usb/EFI first and can
      # hang on flaky SD readers or half-broken EFI partitions. SD rescue
      # still works at the firmware level (BOOT_ORDER=0xf12), so u-boot
      # itself never needs local media. serverip is hardcoded in bootcmd —
      # DHCP-provided boot-server hints are not reliable on this network.
      ubootPxe = let
        ub = pkgs.pkgsCross.aarch64-multiplatform.callPackage
          (pkgs.path + "/pkgs/misc/uboot") {};
        setServer =
          if config.netboot-server.serverIp != null
          then "setenv serverip ${config.netboot-server.serverIp}; "
          else "";
      in
        ub.buildUBoot {
          defconfig = "rpi_4_defconfig";
          filesToInstall = ["u-boot.bin"];
          extraConfig = ''
            # DHCP with patience, then retry the whole PXE sequence forever:
            # after a power cut every Pi comes up long before the netboot
            # server does. Without the while-loop u-boot's bootcmd fails once
            # and drops to the interactive console, hanging the node until a
            # manual power cycle. `reset` is a backstop should the loop ever
            # exit (it shouldn't).
            CONFIG_BOOTCOMMAND="while true; do if dhcp; then ${setServer}pxe get && pxe boot; fi; sleep 10; done; reset"
            # Ignore DHCP option 43 PXE control suboptions: our router
            # attaches a PIXELINUX vendor option that makes strict PXE
            # clients reject its offers.
            # CONFIG_BOOTP_PXE2 is not set
          '';
          extraMeta.platforms = ["aarch64-linux"];
        };

      pushUser = "netboot-push";
    in
      lib.mkIf config.netboot-server.enable {
      netboot-server.uboot = lib.mkDefault ubootPxe;

      # Fleet nodes push their own boot files over SSH as this user. It owns
      # the per-node serial dirs and the pre-created pxelinux.cfg/01-<mac>
      # files — nothing else. One user + one fleet key for all nodes: a
      # compromised node could clobber another node's boot files (accepted
      # tradeoff, home fleet); it can NOT touch the root firmware files or
      # the pxelinux park default (root-owned dir + file).
      users.groups.${pushUser} = {};
      users.users.${pushUser} = {
        isSystemUser = true;
        group = pushUser;
        home = "/var/lib/${pushUser}";
        createHome = true;
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = config.netboot-server.pushAuthorizedKeys;
      };

      services.dnsmasq = {
        enable = true;
        # PXE/TFTP only (port = 0 below): without this, the nixpkgs module's
        # resolveLocalQueries default injects DNS=127.0.0.1 into
        # systemd-resolved while nothing listens on :53 — killing all DNS on
        # this host (broke nix builds: source fetches timed out resolving).
        resolveLocalQueries = false;
        settings = {
          port = 0; # no DNS
          interface = config.netboot-server.interface;
          # Proxy-DHCP + TFTP: this exact combination netbooted rpi1-3.
          # The proxy offers carry our TFTP/boot hints; the router stays
          # authoritative for IPs.
          dhcp-range = "${config.netboot-server.subnet},proxy";
          pxe-service = ["0,Raspberry Pi Boot"];
          dhcp-option = [
            "option:tftp-server,${serverIp}" # 66
            "150,${serverIp}" # alt TFTP server option
          ];
          dhcp-boot = "pxelinux.cfg/default,,${serverIp}";
          enable-tftp = true;
          tftp-root = config.netboot-server.tftpRoot;
          log-dhcp = true;
        };
      };

      # PXE-proxy DHCP + TFTP are UDP; iSCSI is TCP.
      networking.firewall.allowedUDPPorts = [67 69 4011];
      networking.firewall.allowedTCPPorts = [3260];

      # Everything below serves files off the TFTP root, which lives on the
      # data disk (/workspace). If that disk drops (USB enclosure flaps after
      # a power cut), dnsmasq must NOT answer PXE with unreadable/missing
      # files and the sync must NOT recreate the tree on the root SSD.
      systemd.services.dnsmasq.unitConfig.RequiresMountsFor = [config.netboot-server.tftpRoot];

      systemd.services.pi-netboot-sync = {
        description = "Sync Pi netboot baseline (firmware + u-boot + push-writable node dirs) to TFTP root";
        wantedBy = ["multi-user.target"];
        unitConfig.RequiresMountsFor = [config.netboot-server.tftpRoot];
        after = ["local-fs.target"];
        before = ["dnsmasq.service"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        path = with pkgs; [coreutils findutils];

        script = let
          cfg = config.netboot-server;
          # Firmware loads u-boot as its "kernel"; u-boot then PXE-boots the
          # real kernel via pxelinux.cfg. The firmware cannot start large
          # mainline NixOS Images directly (raw or gzipped).
          configTxt = pkgs.writeText "pi-config.txt" ''
            arm_64bit=1
            kernel=kernel8.img
            enable_uart=1
          '';
        in ''
          set -euo pipefail
          root='${cfg.tftpRoot}'
          fw='${cfg.firmware}'
          dtb_name='${cfg.dtbName}'

          mkdir -p "$root/COMMON"
          for f in start4.elf fixup4.dat bootcode.bin "$dtb_name"; do
            src="$(find "$fw" -maxdepth 4 -name "$f" -print -quit)"
            if [ -z "$src" ]; then echo "firmware package is missing $f" >&2; exit 1; fi
            install -m 0644 -D "$src" "$root/COMMON/$f"
          done

          # Firmware boot files + u-boot at the TFTP root (all Pis share these).
          for f in start4.elf fixup4.dat "$dtb_name"; do
            install -m 0644 "$root/COMMON/$f" "$root/$f"
          done
          install -m 0644 ${configTxt} "$root/config.txt"
          install -m 0644 ${cfg.uboot}/u-boot.bin "$root/kernel8.img"

          mkdir -p "$root/pxelinux.cfg"

          # Per-node skeletons. Kernel/initrd/dtb/boot menus are pushed by
          # the nodes themselves — the sync never touches those files.
          ${lib.concatMapStrings (n: ''
            echo "==> node ${n.id} (serial ${n.serial}, ${n.iqn})"
            dir="$root/${n.serial}"
            mkdir -p "$dir"
            chown ${pushUser}:${pushUser} "$dir"

            ${lib.optionalString (n.mac != null) ''
              # Pre-create the per-MAC pxelinux entry push-writable. The dir
              # stays root-owned so the push user cannot replace the park
              # default below — it can only rewrite its own file in place.
              mac_fmt=$(echo "${n.mac}" | tr ':' '-')
              touch "$root/pxelinux.cfg/01-$mac_fmt"
              chown ${pushUser}:${pushUser} "$root/pxelinux.cfg/01-$mac_fmt"
            ''}

            ${lib.optionalString n.firmwareBoot ''
              # Firmware-direct boot: the firmware prefers <serial>/ over
              # the TFTP root, but ONLY while every prefixed probe hits —
              # one miss drops the prefix for the whole boot. So the serial
              # dir must carry the complete boot file set. Firmware blobs
              # and config.txt are static and stay server-managed; the node
              # pushes kernel8.img/initrd/dtb/cmdline.txt itself.
              for f in start4.elf fixup4.dat; do
                install -m 0644 "$root/COMMON/$f" "$dir/$f"
              done
              # dtb: seed only — the node pushes a kernel-matching one
              # afterwards (and owns it from then on).
              if [ ! -f "$dir/$dtb_name" ]; then
                install -m 0644 "$root/COMMON/$dtb_name" "$dir/$dtb_name"
              fi
              # The vc4 display pipeline only exists as a DT overlay on Pi 4
              # (the base dtb has no gpu node) — without it the kernel boots
              # headless and the firmware's rainbow splash stays on screen.
              mkdir -p "$dir/overlays"
              ov="$(find "$fw" -name vc4-kms-v3d-pi4.dtbo -print -quit)"
              if [ -z "$ov" ]; then echo "vc4-kms-v3d-pi4.dtbo missing" >&2; exit 1; fi
              install -m 0644 "$ov" "$dir/overlays/vc4-kms-v3d-pi4.dtbo"
              # The initrd needs an explicit address well past the kernel
              # (0x80000 + ~64MB) — followkernel overshoots on mainline.
              cat > "$dir/config.txt" <<FWEOF
              arm_64bit=1
              kernel=kernel8.img
              initramfs initrd 0x08000000
              dtb=$dtb_name
              dtoverlay=vc4-kms-v3d-pi4
              enable_uart=1
              FWEOF
            ''}
          '') cfg.nodes}

          # The shared "default" config must never auto-boot a specific
          # node's LUN: an UNREGISTERED Pi walking the pxelinux fallback
          # chain would boot it and dual-mount that node's iSCSI root.
          # Unregistered machines get a park menu instead.
          cat > "$root/pxelinux.cfg/default" <<PXEEOF
          menu title netboot fleet — unregistered host
          # Register this Pi in netboot-server.nodes to netboot it.
          label park
            menu label Park (do not boot)
            localboot -1
          PXEEOF

          echo "netboot baseline synced."
        '';
      };
    };
  };
}
