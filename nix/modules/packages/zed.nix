{...}: {
  flake.homeModules.zed = {...}: {
    programs.zed-editor = {
      enable = true;
      userSettings = builtins.fromJSON (builtins.readFile ../../../dotfiles/zed/settings.json);
      userKeymaps = builtins.fromJSON (builtins.readFile ../../../dotfiles/zed/keymap.json);
    };
  };
}
