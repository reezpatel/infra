{inputs, ...}: let
  commonPackagesModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      age
      bat
      curl
      eza
      fd
      fzf
      jq
      ripgrep
      tree
      vim
      wget
      autoenv
      nix-update
      nh
      just
      nushell
      nerd-fonts.jetbrains-mono
      nh
      comma
      # moon (moonrepo task runner) from its own flake — see inputs.moon.
      inputs.moon.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # moon's binary cache (its flake's nixConfig is NOT honored for a
    # dependent flake, so without this every host compiles moon from Rust
    # source — painful on the Pis).
    nix.settings = {
      extra-substituters = ["https://moonrepo.cachix.org"];
      extra-trusted-public-keys = [
        "moonrepo.cachix.org-1:n4zm4mkV1Eoqck4mQvAhJM28EQwFLU7kW4dEbtAXbD8="
      ];
    };
  };
in {
  flake.modules.darwin.common-packages = commonPackagesModule;
  flake.modules.nixos.common-packages = commonPackagesModule;
}
