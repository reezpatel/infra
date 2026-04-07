{
  description = "Central NixOS System Configurator";

  inputs = {
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-k1low = {
      url = "github:k1LoW/homebrew-tap";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs @ {
    darwin,
    home-manager,
    nix-homebrew,
    disko,
    agenix,
    ...
  }: let
    modules = [
      ./modules/options.nix
      ./modules/aliases.nix
      ./modules/home_manager.nix
      ./modules/vim.nix
      ./modules/autojump.nix
      ./modules/system.nix
      ./modules/homebrew.nix
      ./modules/zsh.nix
      ./modules/tmux.nix
      ./modules/nvim.nix
      ./modules/git.nix
      ./modules/home_manager.nix
      ./modules/environment.nix
      ./modules/macos.nix
      ./modules/linux.nix
      ./modules/gpu.nix
    ];
  in {
    lib.mkDarwin = {
      options,
      pkgs,
      ...
    }:
      darwin.lib.darwinSystem {
        system = pkgs.stdenv.hostPlatform.system;
        specialArgs =
          inputs
          // {
            inherit pkgs;
          };
        modules =
          modules
          ++ [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            agenix.nixosModules.default
            {
              core = options;
            }
          ];
      };

    lib.mkLinux = {
      options,
      pkgs,
      ...
    }: {
      specialArgs =
        inputs
        // {
          inherit pkgs;
        };
      modules =
        modules
        ++ [
          home-manager.nixosModules.home-manager
          disko.nixosModules.disko
          agenix.nixosModules.default
          {
            core = options;
          }
        ];
    };

    lib.mkPi = {
      options,
      pkgs,
      ...
    }: {
      specialArgs =
        inputs
        // {
          inherit pkgs;
        };
      modules =
        modules
        ++ [
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          {
            core = options;
          }
        ];
    };
  };
}
