{lib, config, ...}: {
  options.moduleRegistry = {
    darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = {};
      description = "Internal registry for reusable nix-darwin modules.";
    };

    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = {};
      description = "Internal registry for reusable NixOS modules.";
    };
  };

  options.flake.darwinConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "Darwin system configurations.";
  };

  config.flake = {
    darwinModules = config.moduleRegistry.darwin;
    nixosModules = config.moduleRegistry.nixos;
  };
}
