{...}: {
  flake.modules.nixos.gui_apps = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      slack
      karere
      discord
      telegram-desktop
      kicad
    ];
  };
}
