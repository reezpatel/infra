{ ... }: {
  flake.modules.nixos.kde =
    {
      lib,
      pkgs,
      ...
    }:
    {
      # nixpkgs' plasma6 module enables fwupd at mkDefault priority. fwupd is an
      # explicit choice here (see the `firmware` module, wired into the `server`
      # aspect), so undo the implicit default at a priority that still lets the
      # firmware module's plain definition win: mkDefault=1000 < this=900 < plain=100.
      services.fwupd.enable = lib.mkOverride 900 false;

      programs = {
        kdeconnect.enable = true;
        partition-manager.enable = true;
      };

      xdg.portal = {
        enable = true;
        config.common.default = "kde";
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
        ];
      };

      networking.firewall = rec {
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = allowedTCPPortRanges;
      };

      services = {
        dbus.enable = true;
        libinput.enable = true;
        printing.enable = true;

        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        xserver = {
          enable = true;
          xkb.options = "eurosign:e";
        };

        displayManager.sddm = {
          enable = true;
          wayland.enable = true;
        };

        desktopManager.plasma6.enable = true;
      };

      environment.systemPackages = with pkgs; [
        kdePackages.ark
        kdePackages.filelight
        kdePackages.kate
        kdePackages.kcalc
        kdePackages.kdialog
        kdePackages.kgpg
        kdePackages.kpipewire
        kdePackages.krdc
        kdePackages.krfb
        kdePackages.kscreen
        kdePackages.ksystemlog
        kdePackages.okular
        kdePackages.plasma-browser-integration
        kdePackages.sddm-kcm
        kdePackages.spectacle
        kdePackages.xdg-desktop-portal-kde
        kdePackages.yakuake
        vlc
      ];

      system.userActivationScripts.restart-plasma = ''
        ${pkgs.xdg-utils}/bin/xdg-desktop-menu forceupdate
      '';

      # Never sleep/suspend/hibernate - these are always-on workstations.
      systemd.targets.sleep.enable = false;
      systemd.targets.suspend.enable = false;
      systemd.targets.hibernate.enable = false;
      systemd.targets.hybrid-sleep.enable = false;

      # Power button / lid close must not suspend or power off either.
      services.logind.settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
      };
    };
}
