{inputs, ...}: {
  moduleRegistry.nixos.helium = {
    lib,
    pkgs,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
    packages = inputs.helium.packages;
    isSupported = builtins.hasAttr system packages;
    helium = packages.${system}.default;
  in {
    warnings = lib.optional (!isSupported) ''
      Skipping Helium: no package is defined for ${system}.
    '';

    environment.systemPackages = lib.optionals isSupported [
      helium
    ];
  };
}
