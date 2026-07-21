{...}: {
  flake.homeModules.clipboard = {pkgs, ...}: {
    home.packages = with pkgs; [
      wl-clipboard
    ];
  };
}
