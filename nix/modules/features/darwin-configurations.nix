{lib, ...}: {
  # `darwinConfigurations` is not a built-in flake-parts option; declare it so
  # host files can set `flake.darwinConfigurations.<name>`.
  options.flake.darwinConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "nix-darwin system configurations.";
  };
}
