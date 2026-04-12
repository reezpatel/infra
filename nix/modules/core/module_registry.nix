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

  config.flake = {
    darwinModules = config.moduleRegistry.darwin;
    nixosModules = config.moduleRegistry.nixos;
  };
}
