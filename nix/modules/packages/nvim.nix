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
        gitsign

        # LSP servers
        lua-language-server
        typescript-language-server
        vscode-langservers-extracted
        tailwindcss-language-server
        bash-language-server
        yaml-language-server

        # golang
        gopls
        golangci-lint
        gotools
        go-migrate
        delve

        # Formatters
        stylua
        prettierd
        prettier
        black
        gofumpt
        beautysh

        # Linters
        markdownlint-cli
        eslint_d

        # Tools
        ripgrep
        fzf
        lazygit
        delve

        # nix
        nil
        nixd
        alejandra
        nixfmt

        #terraform
        terraform-ls
        tflint
      ];
    };

    xdg.configFile = {
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "/Users/reezpatel/infra/dotfiles/nvim";
    };
  };
}
