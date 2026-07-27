{...}: {
  moduleRegistry.nixos.discord = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.discord
    ];
  };
}
