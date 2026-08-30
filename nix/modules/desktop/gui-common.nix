{...}: {
  flake.modules.nixos.gui-common = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
    ];
  };
}
