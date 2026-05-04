{...}: {
  flake.homeModules.nvim = {
    pkgs,
    config,
    ...
  }: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      extraLuaConfig = "";
    };

    xdg.configFile = {
      "nvim".source =
        if pkgs.stdenv.isDarwin
        then config.lib.file.mkOutOfStoreSymlink "/Users/reezpatel/infra/dotfiles/nvim"
        else ../../../dotfiles/nvim;
    };
  };
}
