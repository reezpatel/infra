{inputs, ...}: {
  flake.modules.homeManager.antigravity = {pkgs, ...}: let
    packages = inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    home.packages = with packages; [
      google-antigravity-ide
      google-antigravity-cli
    ];
  };
}
