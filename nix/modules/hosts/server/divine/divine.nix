{
  inputs,
  self,
  ...
}: let
  system = "x86_64-linux";
in {
  flake.nixosConfigurations.divine = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.agenix.nixosModules.default

      ./_disko.nix
      ./_hardware-configuration.nix

      self.nixosModules.config
      self.nixosModules.system
      self.nixosModules.nvidia_gpu
      self.nixosModules.shellAlias
      self.nixosModules.shellFunctions

      self.nixosModules.commonPackages
      self.nixosModules.advancedPackages
      self.nixosModules.parsec

      self.nixosModules.samba
      self.nixosModules.ollama
      self.nixosModules.tailscale
      self.nixosModules.monitoringClient
      self.nixosModules.kde

      self.nixosModules.helium
      self.nixosModules.gui_common

      {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "divine";
        nvidiaGpu.enableCuda = false;
        programs.niri.enable = true;
        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;
        services.hardware.bolt.enable = true;
        hardware.bluetooth.enable = true;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

        system.stateVersion = "26.05";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "before-hm";

          users.reezpatel = {...}: {
            home = {
              stateVersion = "26.05";
            };

            imports = [
              inputs.agenix.homeManagerModules.default
              inputs.noctalia.homeModules.default
              self.homeModules.zsh
              self.homeModules.tmux
              self.homeModules.vim
              self.homeModules.nvim
              self.homeModules.git
              self.homeModules.autojump
              self.homeModules.fastfetch
              self.homeModules.opencode
              self.homeModules.claude-code
              self.homeModules.codex
              self.homeModules.antigravity
              self.homeModules.zed
              self.homeModules.ghostty
            ];

            programs.noctalia-shell = {
              enable = true;
              settings = {
                bar = {
                  density = "compact";
                  position = "top";
                };
                colorSchemes.predefinedScheme = "Monochrome";
                general.radiusRatio = 0.2;
              };
            };

            xdg.configFile."niri/config.kdl".text = ''
              spawn-at-startup "noctalia-shell"
              spawn-at-startup "xwayland-satellite"

              output "DP-5" {
                mode "3840x2160@59.997"
                scale 1.25
                position x=0 y=0
                transform "normal"
              }

              output "HDMI-A-1" {
                off
              }

              input {
                keyboard {
                  xkb {
                    layout "us"
                  }
                }
              }

              binds {
                Mod+Return { spawn "kitty"; }
                Mod+D { spawn "fuzzel"; }
                Mod+Q { close-window; }
                Mod+Shift+E { quit; }
              }

              window-rule {
                geometry-corner-radius 20
                clip-to-geometry true

                background-effect {
                  blur true
                  xray false
                }
              }

              layer-rule {
                match namespace="^noctalia-wallpaper*"
                place-within-backdrop true
              }

              layer-rule {
                match namespace="^noctalia-(background|launcher-overlay|dock)-.*$"

                background-effect {
                  xray false
                }
              }

              layout {
                background-color "transparent"
              }

              overview {
                workspace-shadow {
                  off
                }
              }

              debug {
                honor-xdg-activation-with-invalid-serial
              }
            '';
          };
        };
      }

      (
        {
          config,
          pkgs,
          ...
        }: {
          virtualisation.docker = {
            enable = true;
            enableOnBoot = true;
            autoPrune.enable = true;
          };

          users.users.${config.username}.extraGroups = ["docker"];

          environment.systemPackages = with pkgs; [
            mergerfs
            mdadm
            lsof
            uv
            gcc
            gnumake
            git
            pkg-config
            stdenv.cc.cc.lib
            ffmpeg
            docker-compose
            xwayland-satellite
            kitty
            fuzzel
            wl-clipboard
            grim
            slurp
            bolt
          ];
        }
      )

      (
        {
          config,
          lib,
          pkgs,
          ...
        }: {
          services.displayManager.sddm.enable = lib.mkForce false;
          services.greetd = {
            enable = true;
            settings = {
              initial_session = {
                command = "niri-session";
                user = config.username;
              };
              default_session = {
                command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions";
                user = "greeter";
              };
            };
          };
          systemd.services.fwupd-refresh.enable = lib.mkForce false;
          systemd.timers.fwupd-refresh.enable = lib.mkForce false;
          boot.kernelParams = [
            "usbcore.autosuspend=-1"
          ];

          # Assemble mdadm RAID arrays at boot
          boot.swraid.enable = true;
          boot.swraid.mdadmConf = ''
            MAILADDR root
          '';

          fileSystems."/mnt/ssd" = lib.mkForce {
            device = "/dev/md/raid1-ssd1";
            fsType = "xfs";
            options = [
              "noatime"
              "nofail"
            ];
          };

          services.nfs.server = {
            enable = true;
            exports = ''
              /mnt/ssd    192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
              /mnt/nvme1  192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
            '';
          };

          # NFS server should wait for mounts
          systemd.services.nfs-server = {
            after = [
              "mnt-ssd.mount"
              "mnt-nvme1.mount"
            ];
            wants = [
              "mnt-ssd.mount"
              "mnt-nvme1.mount"
            ];
          };
        }
      )

      {
        fileSystems."/mnt/mergefs" = {
          device = "/mnt/weed/sda:/mnt/weed/sdb";
          fsType = "fuse.mergerfs";
          options = [
            "defaults"
            "nofail"
            "allow_other"
            "use_ino"
            "cache.files=partial"
            "dropcacheonclose=true"
            "category.create=mfs" # place new files on disk with most free space
          ];
        };
      }
    ];
  };
}
