{
  user,
  pkgs,
  ...
}:
{
  virtualisation.docker.enable = true;

  # GUI
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = user;
  services.desktopManager.gnome.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Services
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

}
