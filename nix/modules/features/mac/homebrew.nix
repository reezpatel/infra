{inputs, ...}: {
  # Owns its own external dependency: hosts get nix-homebrew simply by
  # importing this module.
  flake.modules.darwin.homebrew = {config, ...}: {
    imports = [inputs.nix-homebrew.darwinModules.nix-homebrew];

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
        "netbirdio/homebrew-tap" = inputs.homebrew-netbirdio-tap;
      };
      mutableTaps = false;
      autoMigrate = true;
    };
  };
}
