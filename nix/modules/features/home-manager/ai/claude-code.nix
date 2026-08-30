{inputs, ...}: {
  flake.modules.homeManager.claude-code = {pkgs, ...}: let
    claudePkgs = pkgs.extend inputs.claude-code.overlays.default;
  in {
    home.packages = [
      claudePkgs.claude-code
    ];
  };
}
