# Netbooted Raspberry Pi client: firmware/kernel over TFTP from the netboot
# server, root on an iSCSI LUN attached in the (systemd) initrd with
# iscsistart. Upstream NixOS has no first-class initrd iSCSI support, so this
# wires the pieces together: network in initrd + iscsi_tcp + a oneshot unit
# ordered before initrd-root-device.target.
{
  ...
}:
{
  flake.modules.nixos.rpi-netboot =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
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

        firmwareBoot = lib.mkEnableOption ''
          firmware-direct boot (no u-boot): push kernel8.img/initrd/dtb/
          cmdline.txt into the serial dir instead of a pxelinux menu entry.
          Must match the server-side nodes[].firmwareBoot flag
        '';

        dtbName = lib.mkOption {
          type = lib.types.str;
          default = "bcm2711-rpi-4-b.dtb";
          description = "Device tree pushed next to the kernel (Pi 4 Model B).";
        };

        # This node maintains its own boot files on the server's TFTP tree,
        # so deploying a node (or just rebooting it) can never desync the
        # TFTP boot files from the closure installed on its LUN — the same
        # running closure writes both sides. Pushing runs (a) in an
        # activation script on every nixos-rebuild switch and (b) in a
        # oneshot service on every boot; both read /run/current-system, so
        # they always publish exactly what is running.
        push = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Push this node's boot files to the netboot server after every
              switch and boot. Disable only for nodes whose host key is not
              yet a recipient of secerts/netboot-push-key.age.
            '';
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "netboot-push";
            description = "SSH user on the netboot server (see netboot-server.pushAuthorizedKeys).";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 7272;
            description = "SSH port on the netboot server.";
          };

          tftpRoot = lib.mkOption {
            type = lib.types.str;
            default = "/workspace/tftpboot";
            description = "TFTP root path ON THE SERVER (must match netboot-server.tftpRoot).";
          };

          keyPath = lib.mkOption {
            type = lib.types.str;
            default = "/run/agenix/netboot-push-key";
            description = "Path of the decrypted fleet push key on this node.";
          };
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

      config =
        let
          cfg = config.netboot;
          # Uploads the running closure's boot files to the server's TFTP tree.
          # Always exits 0 — a failed push (server down, key missing) must never
          # break activation or boot; the next switch/boot retries.
          pushScript = pkgs.writeShellApplication {
            name = "netboot-boot-push";
            runtimeInputs = with pkgs; [
              coreutils
              findutils
              gawk
              openssh
            ];
            text = ''
                      set +o errexit  # writeShellApplication enables it; push must be non-fatal

                      key='${cfg.push.keyPath}'
                      if [ ! -r "$key" ]; then
                        echo "netboot-boot-push: $key missing/undecryptable, skipping" >&2
                        exit 0
                      fi

                      tl=$(readlink -f /run/current-system)
                      if [ ! -e "$tl/kernel" ] || [ ! -e "$tl/initrd" ]; then
                        echo "netboot-boot-push: $tl has no kernel/initrd, skipping" >&2
                        exit 0
                      fi

                      # Mainline arm64 /proc/cpuinfo has no Serial line; the firmware
              # passes it via the device tree instead. This must match the
              # EEPROM's TFTP prefix dir (last 8 of the board serial).
              serial=$(tr -d '\0' < /sys/firmware/devicetree/base/serial-number 2>/dev/null | rev | cut -c1-8 | rev)
              if [ -z "$serial" ]; then
                serial=$(awk '/^Serial/ {print $NF}' /proc/cpuinfo | rev | cut -c1-8 | rev)
              fi
              if [ -z "$serial" ]; then
                echo "netboot-boot-push: cannot determine board serial, skipping" >&2
                exit 0
              fi
                      host='${cfg.push.user}@${cfg.serverIp}'
                      root='${cfg.push.tftpRoot}'
                      dtb_name='${cfg.dtbName}'
                      # Kernel-matching dtb (toplevel dtbs are in per-vendor subdirs,
                  # e.g. dtbs/broadcom/bcm2711-rpi-4-b.dtb).
                  dtb=$(find -L "$tl/dtbs" -name "$dtb_name" -print -quit)
                      params=$(cat "$tl/kernel-params")

                      ssh_cmd=(ssh -i "$key" -p ${toString cfg.push.port} -o IdentitiesOnly=yes -o BatchMode=yes \
                        -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null)

                      # Atomic replace inside the push-owned serial dir.
                      put() { # put <local> <remote-abs>
                        "''${ssh_cmd[@]}" "$host" \
                          "cat > '$2.push-tmp' && chmod 0644 '$2.push-tmp' && mv '$2.push-tmp' '$2'" < "$1" \
                          && echo "pushed $2" || echo "netboot-boot-push: FAILED $2" >&2
                      }

                      ${
                        if cfg.firmwareBoot then
                          ''
                            # Firmware-direct: the firmware loads these straight from the
                            # serial dir (config.txt + firmware blobs are server-seeded).
                            put "$tl/kernel" "$root/$serial/kernel8.img"
                            put "$tl/initrd" "$root/$serial/initrd"
                            if [ -n "$dtb" ]; then put "$dtb" "$root/$serial/$dtb_name"; fi
                            cmdline=$(mktemp)
                            printf '%s\n' "$params init=$tl/init systemConfig=$tl" > "$cmdline"
                            put "$cmdline" "$root/$serial/cmdline.txt"
                            rm -f "$cmdline"
                          ''
                        else
                          ''
                              # u-boot PXE: kernel/initrd/dtb in the serial dir + a per-MAC
                              # pxelinux menu entry. The pxelinux.cfg DIR is root-owned and
                              # the 01-<mac> file server-pre-created push-owned: overwrite in
                              # place, no rename. If the server never pre-created it (node
                              # registered without a mac), this fails with a warning — add
                              # the mac to netboot-server.nodes.
                              put "$tl/kernel" "$root/$serial/Image"
                              put "$tl/initrd" "$root/$serial/initrd"
                              if [ -n "$dtb" ]; then put "$dtb" "$root/$serial/$dtb_name"; fi
                              mac_fmt=$(tr 'A-F' 'a-f' < /sys/class/net/eth0/address | tr ':' '-')
                              id=$(cat /etc/hostname)
                              entry=$(mktemp)
                              cat > "$entry" <<PXEEOF
                            menu title netboot fleet
                            default $id
                            timeout 20
                            label $id
                              menu label NixOS $id
                              kernel /$serial/Image
                              initrd /$serial/initrd
                              fdt /$serial/$dtb_name
                              append $params init=$tl/init systemConfig=$tl
                            PXEEOF
                              "''${ssh_cmd[@]}" "$host" "cat > '$root/pxelinux.cfg/01-$mac_fmt'" < "$entry" \
                                && echo "pushed pxelinux.cfg/01-$mac_fmt" \
                                || echo "netboot-boot-push: FAILED pxelinux.cfg/01-$mac_fmt (pre-created on server?)" >&2
                              rm -f "$entry"
                          ''
                      }
                      exit 0
            '';
          };
        in
        {
          # No local boot media at all — firmware is fetched over TFTP.
          # mkForce: features/linux/system.nix enables systemd-boot for the
          # regular EFI hosts; letting it win makes switch-to-configuration
          # run the systemd-boot installer, which fails on the missing /boot.
          boot.loader.systemd-boot.enable = lib.mkForce false;
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

          # DHCP with the MAC as client-id everywhere: NetworkManager
          # otherwise sends a DUID-LLT (option 61), which MikroTik matches
          # leases by — MAC-based static leases never match, and the booted
          # OS ends up on a different address than the initrd/u-boot stages
          # (which already use the MAC). One identity per board.
          environment.etc."NetworkManager/conf.d/90-dhcp-client-id.conf".text = ''
            [connection]
            ipv4.dhcp-client-id=mac
          '';

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
              wantedBy = [ "initrd-root-device.target" ];
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

          fileSystems = {
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

          # Fleet push key (private half); the public half lives in
          # netboot-server.pushAuthorizedKeys on the server. Only declared when
          # pushing is enabled — a node whose host key is not a recipient of
          # this secret would otherwise fail agenix on every activation.
          age.secrets.netboot-push-key = lib.mkIf cfg.push.enable {
            file = ../../../../secerts/netboot-push-key.age;
            mode = "0400";
          };

          # Push on every switch (activation, after agenix installs the key)…
          system.activationScripts.netbootBootPush = lib.mkIf cfg.push.enable {
            deps = [
              "agenix"
              "agenixChown"
            ];
            text = ''
              ${pushScript}/bin/netboot-boot-push || echo "netboot-boot-push failed (non-fatal)" >&2
            '';
          };

          # …and on every boot (covers `nixos-rebuild boot` + reboot, and
          # retries a push that failed because the server was down).
          systemd.services = lib.mkMerge [
            (lib.mkIf cfg.push.enable {
              netboot-boot-push = {
                description = "Push kernel/initrd/boot config to the netboot server TFTP tree";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                script = "${pushScript}/bin/netboot-boot-push";
              };
            })
            (lib.mkIf cfg.sdBoot.enable {
              # Syncs kernel/initrd/cmdline from the RUNNING closure to the SD.
              # Runs at boot (ExecStart) and at shutdown/reboot (ExecStop), so a
              # `nixos-rebuild switch` followed by a reboot writes the new kernel
              # to the SD before the machine goes down. Reading /run/current-system
              # (not config.system.build.toplevel) avoids infinite recursion.
              boot-sd-sync = {
                description = "Sync kernel/initrd/firmware to the SD boot partition";
                wantedBy = [ "multi-user.target" ];
                before = [
                  "shutdown.target"
                  "reboot.target"
                ];
                after = [ "local-fs.target" ];

                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };

                path = with pkgs; [
                  coreutils
                  findutils
                ];

                script =
                  let
                    fw = cfg.sdBoot.firmwarePackage;
                  in
                  ''
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
            })
          ];
        };
    };
}
