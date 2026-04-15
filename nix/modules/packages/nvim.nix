{...}: {
  flake.homeModules.nvim = {
    pkgs,
    config,
    ...
  }: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [

      ];
    };

    xdg.configFile = {
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "/Users/reezpatel/infra/dotfiles/nvim";
    };
  };
}
