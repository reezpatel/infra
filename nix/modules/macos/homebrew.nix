{inputs, ...}: {
  moduleRegistry.darwin.homebrew = {config, ...}: {
    homebrew = {
      enable = true;

      global.autoUpdate = true;
      greedyCasks = true;

      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    nix-homebrew = {
      user = config.username;

      enable = true;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
        "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        "edouard-claude/homebrew-tap" = inputs.homebrew-edouard-claude-tap;
      };
      mutableTaps = false;
      autoMigrate = true;
    };
  };
}
