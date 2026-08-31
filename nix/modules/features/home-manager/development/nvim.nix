{...}: {
  # Feature: nvim (homeManager) — neovim editor.
  #
  # Language servers come from the sibling `lsp` module (imported above),
  # living in the user's home profile instead of the system-wide
  # advanced-packages set: they are only useful alongside an editor.
  flake.modules.homeManager.nvim = {
    pkgs,
    config,
    ...
  }: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      sideloadInitLua = true;
      initLua = "";
    };

    xdg.configFile = {
      "nvim".source =
        if pkgs.stdenv.hostPlatform.isDarwin
        then config.lib.file.mkOutOfStoreSymlink "/Users/reezpatel/infra/dotfiles/nvim"
        else ../../../../../dotfiles/nvim;
    };
  };
}
