{...}: {
  moduleRegistry.nixos.kde = {pkgs, ...}: {
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
      kdePackages.dolphin
      kdePackages.filelight
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kdialog
      kdePackages.kgpg
      kdePackages.kpipewire
      kdePackages.krdc
      kdePackages.krfb
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
  };
}
