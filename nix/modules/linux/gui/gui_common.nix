{...}: {
  moduleRegistry.nixos.gui_common = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
    ];
  };
}
