{ inputs, ... }:
{
  flake.homeModules.antigravity =
    { pkgs, ... }:
    let
      packages = inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = with packages; [
        default
        google-antigravity-ide
        google-antigravity-cli
      ];
    };
}
