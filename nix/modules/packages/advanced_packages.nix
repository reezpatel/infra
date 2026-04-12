{inputs, ...}: let
  advancedPackagesModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs;
      [
        postgresql.out
        go
        gcc
        kubectl
        nodejs_22
        yarn
        pnpm

        # firebase-tools
        python3
        uv
        nerd-fonts.jetbrains-mono

        nh
        ollama

        comma

        # glow # Markdown renderer for terminal
        # iftop # Network bandwidth monitor
        #
      ]
      ++ [inputs.agenix.packages.${pkgs.stdenv.system}.default];
  };
in {
  moduleRegistry.darwin.advancedPackages = advancedPackagesModule;
  moduleRegistry.nixos.advancedPackages = advancedPackagesModule;
}
