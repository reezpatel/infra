{
  inputs,
  self,
  ...
}:
let
  system = "x86_64-linux";
in
{
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
      self.nixosModules.gpu_handover
      self.nixosModules.shellAlias
      self.nixosModules.shellFunctions

      self.nixosModules.commonPackages
      self.nixosModules.advancedPackages
      self.nixosModules.parsec

      self.nixosModules.samba
      self.nixosModules.ollama
      self.nixosModules.pi
      self.nixosModules.tailscale
      self.nixosModules.monitoringClient
      self.nixosModules.kde

      self.nixosModules.helium
      self.nixosModules.whatsapp
      self.nixosModules.discord
      self.nixosModules.telegram
      self.nixosModules.gui_common
      self.nixosModules.windows-apps
      self.nixosModules.gaming
      self.nixosModules.kicad
      self.nixosModules.mac-keyboard

      {
        nixpkgs.config.allowUnfree = true;

        nixpkgs.overlays = [
          (_final: prev: {
            nrfutil = prev.nrfutil.override {
              versionCheckHook = prev.emptyDirectory;
            };
          })
        ];

        username = "reezpatel";
        hostname = "divine";
        nvidiaGpu.enableCuda = false;
        programs.niri.enable = true;
        macKeyboard.enable = true;
        windowsApps.enable = true;
        gaming.enable = true;
        kicad.enable = true;

        # Dynamic GPU/Thunderbolt handover to the Windows VM (NOT static
        # passthrough - host keeps the devices until `virsh start win11`).
        gpuHandover = {
          enable = true;
          vmName = "win11";

          # RTX 3090 + HDMI/DP audio function (confirmed via lspci)
          gpuPciAddress = "0000:01:00.0";
          gpuAudioPciAddress = "0000:01:00.1";

          # Host desktop runs ON the 3090: starting the VM stops the niri
          # session, hands the 3090 to Windows (use a monitor on the 3090's
          # outputs), and on VM shutdown greetd auto-logs back into niri.
          #
          # No PCI handover besides the GPU - mouse/keyboard/speaker are
          # plain USB hostdevs in win11.xml (auto-attach/detach with the VM).
          servicesToStop = [
            "ollama.service"
            "docker.service"
          ];

          # 64 GiB for the VM (allocated only while it runs)
          hugepagesGB = 64;
        };

        # VM disk/ISO storage lives on the SSD RAID array (user-writable;
        # qemu runs as root so it can read/write regardless)
        systemd.tmpfiles.rules = [
          "d /mnt/ssd/windows 0755 reezpatel root -"
        ];
        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;
        services.hardware.bolt.enable = true;
        services.gvfs.enable = true;
        services.udisks2.enable = true;
        services.printing.enable = true;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
        hardware.bluetooth.enable = true;

        # Disable systemd-oomd to prevent aggressive process killing
        # (especially problematic without swap configured)
        systemd.oomd.enable = false;

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

        system.stateVersion = "26.05";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "before-hm";

          users.reezpatel = { pkgs, ... }: {
            home = {
              stateVersion = "26.05";
              packages = with pkgs; [
                flatpak
              ];
              sessionVariables = {
                XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
              };
            };

            imports = [
              inputs.agenix.homeManagerModules.default
              (import ./_packages/noctalia.nix inputs)
              inputs.nix-flatpak.homeManagerModules.nix-flatpak
              (import ./_packages/niri.nix inputs)
              inputs.nsticky.homeModules.default
              inputs.nfsm-flake.homeModules.default
              self.homeModules.zsh
              self.homeModules.tmux
              self.homeModules.vim
              self.homeModules.nvim
              self.homeModules.git
              self.homeModules.autojump
              self.homeModules.fastfetch
              self.homeModules.opencode
              self.homeModules.pi
              self.homeModules.claude-code
              self.homeModules.codex
              self.homeModules.antigravity
              self.homeModules.zed
              self.homeModules.ghostty
              self.homeModules.kitty
              self.homeModules.clipboard
              self.homeModules.herdr
            ];

            # Configure nsticky for sticky window management
            programs.nsticky = {
              enable = true;
              settings = {
                sticky = {
                  # Automatically make YouTube picture-in-picture windows sticky
                  picture-in-picture.title = "^Picture in picture$";
                };
              };
            };

            services.nfsm.enable = true;

            programs.yazi = {
              enable = true;
              enableZshIntegration = true;
            };

            gtk = {
              enable = true;
              theme = {
                name = "Colloid-Dark";
                package = pkgs.colloid-gtk-theme;
              };
            };

            xdg.configFile."mako/config".text = ''
              anchor=top-right
              margin=16
              padding=12
              border-size=2
              border-radius=12
              default-timeout=5000
              max-visible=5
              layer=overlay
              font=JetBrainsMonoNL NFM 11

              background-color=#1a1b26ee
              text-color=#c0caf5ff
              border-color=#7aa2f7ff
              progress-color=over #414868ff

              [urgency=high]
              border-color=#f7768eff
              default-timeout=0
            '';

            systemd.user.services.mako = {
              Unit = {
                Description = "Mako notification daemon";
                After = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${pkgs.mako}/bin/mako";
                Restart = "always";
                RestartSec = 3;
                Type = "simple";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };

            systemd.user.services.elephant = {
              Unit = {
                Description = "Elephant backend for Walker";
                After = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${pkgs.elephant}/bin/elephant";
                Restart = "always";
                RestartSec = 3;
                Type = "simple";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };

            # Flatpak configuration for Orca Slicer
            # Using official Orca Slicer from Flathub instead of Snapmaker fork
            # (Snapmaker version was crashing on startup)
            services.flatpak = {
              enable = true;
              update.auto.enable = true;
              packages = [
                "com.orcaslicer.OrcaSlicer"
                "com.ticktick.TickTick"
              ];

              # Override settings for better graphics performance
              overrides = {
                "com.orcaslicer.OrcaSlicer" = {
                  Context = {
                    # Enable GPU/graphics access for 3D viewport
                    devices = [ "dri" ];
                    # Grant access to graphics drivers
                    filesystems = [
                      "/run/opengl-driver:ro"
                      "/run/opengl-driver-32:ro"
                    ];
                  };
                };
              };
            };

          };
        };
      }

      (
        {
          config,
          pkgs,
          ...
        }:
        let
          ndrop = pkgs.writeShellApplication {
            name = "ndrop";
            runtimeInputs = with pkgs; [
              bash
              getopt
              iputils
              jq
              libnotify
              niri
            ];
            text = ''
              exec ${pkgs.bash}/bin/bash ${
                pkgs.fetchurl {
                  url = "https://raw.githubusercontent.com/Schweber/ndrop/main/ndrop";
                  sha256 = "0s49hsyxfwcsyliad1nihlqaljsa3jbqsajj2hasmivmmmm18cdp";
                }
              } "$@"
            '';
          };
          freedownloadmanager = pkgs.stdenv.mkDerivation rec {
            pname = "freedownloadmanager";
            version = "latest";

            src = pkgs.fetchurl {
              url = "https://dn3.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
              sha256 = "0a84dpjh1w1da9gc58zv8lny3fdbjmvibcmiha2lws2900542zxg";
            };

            nativeBuildInputs = with pkgs; [
              autoPatchelfHook
              dpkg
              makeWrapper
            ];

            buildInputs = with pkgs; [
              alsa-lib
              atk
              cairo
              cups
              dbus
              fontconfig
              freetype
              gdk-pixbuf
              glib
              gtk3
              harfbuzz
              libGL
              libdrm
              libpulseaudio
              libxkbcommon
              nss
              openssl
              pango
              wayland
              libice
              libsm
              libx11
              libxcomposite
              libxcursor
              libxdamage
              libxext
              libxfixes
              libxi
              libxrandr
              libxrender
              libxtst
              xcbutil
              xcbutilcursor
              xcbutilimage
              xcbutilrenderutil
              xcbutilwm
              zlib
            ];

            unpackPhase = ''
              dpkg-deb -x $src .
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/opt $out/bin $out/share/applications $out/share/pixmaps
              cp -R opt/freedownloadmanager $out/opt/
              cp usr/share/applications/freedownloadmanager.desktop $out/share/applications/
              cp opt/freedownloadmanager/icon.png $out/share/pixmaps/freedownloadmanager.png

              rm -f $out/opt/freedownloadmanager/plugins/imageformats/libqtiff.so
              rm -f $out/opt/freedownloadmanager/plugins/sqldrivers/libqsql{ibase,mimer,mysql,oci,odbc,psql}.so

              substituteInPlace $out/share/applications/freedownloadmanager.desktop \
                --replace-fail "Exec=/opt/freedownloadmanager/fdm" "Exec=fdm" \
                --replace-fail "Icon=/opt/freedownloadmanager/icon.png" "Icon=freedownloadmanager"

              makeWrapper $out/opt/freedownloadmanager/fdm $out/bin/fdm \
                --set QT_QPA_PLATFORM wayland \
                --prefix LD_LIBRARY_PATH : $out/opt/freedownloadmanager/lib

              runHook postInstall
            '';

            meta = {
              description = "Free Download Manager packaged from the official Linux deb";
              homepage = "https://www.freedownloadmanager.org/";
              platforms = [ "x86_64-linux" ];
            };
          };
        in
        {
          virtualisation.docker = {
            enable = true;
            enableOnBoot = true;
            autoPrune.enable = true;
          };

          services.printing.drivers = with pkgs; [
            brgenml1lpr
            brgenml1cupswrapper
          ];

          users.users.${config.username}.extraGroups = [
            "docker"
            "video"
            "dialout"
            "tty"
            "lp"
            "scanner"
          ];

          services.udev.extraRules = ''
            # sigrok fx2lafw logic analyzers (e.g. Saleae clones)
            SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", MODE="0660", GROUP="users"
            ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", MODE="0660", GROUP="users"

            # Seeed Studio devices (all XIAO boards, CMSIS-DAP debuggers)
            ACTION=="add|change", SUBSYSTEM=="usb",    ATTR{idVendor}=="2886", MODE="0660", GROUP="dialout", TAG+="uaccess"
            ACTION=="add|change", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2886", MODE="0660", GROUP="dialout", TAG+="uaccess"
          '';

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
            swaybg
            ndrop
            walker
            elephant
            nemo
            libnotify
            playerctl
            brightnessctl
            wl-clipboard
            grim
            slurp
            bolt
            awscli2
            arduino-ide
            beekeeper-studio
            freedownloadmanager
            vscode
            basedpyright
            ruff

            sftool
            pulseview
            sigrok-firmware-fx2lafw

            nrfutil
            nrfconnect-bluetooth-low-energy

            terraform
          ];
        }
      )

      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          services.displayManager.sddm.enable = lib.mkForce false;
          # plasma6 and niri both set defaultSession at equal priority in
          # nixpkgs; niri is the session this host actually uses.
          services.displayManager.defaultSession = lib.mkForce "niri";
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

      # Enable nix-ld for running dynamically linked binaries (like Zed's codex-acp)
      ({ pkgs, ... }: {
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            openssl
            curl
            libgcc
          ];
        };
      })
    ];
  };
}
