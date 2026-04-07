{
  lib,
  pkgs,
  config,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  homebrew-k1low,
  ...
}:
let
  user = config.core.username;
in
lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  homebrew = {
    enable = true;

    global.autoUpdate = true;
    greedyCasks = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    masApps = config.core.brewMacApps;
    brews = config.core.brewPackages;
    casks = config.core.brewCasks;
  };

  nix-homebrew = {
    user = user;
    enable = true;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
      "k1low/homebrew-tap" = homebrew-k1low;
    };
    mutableTaps = false;
    autoMigrate = true;
  };

}
