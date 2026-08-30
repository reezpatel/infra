{...}: {
  flake.modules.nixos.whatsapp = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.karere
    ];
  };
}
