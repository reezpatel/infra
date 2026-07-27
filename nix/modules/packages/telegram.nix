{...}: {
  moduleRegistry.nixos.telegram = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.telegram-desktop
    ];
  };
}
