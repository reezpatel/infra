{inputs, ...}: {
  flake.modules.homeManager.codex = {pkgs, ...}: {
    home.packages = [
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
