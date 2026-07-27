{...}: {
  moduleRegistry.nixos.whatsapp = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.karere
    ];
  };
}
