{
  pkgs,
  config,
  lib,
  ...
}: let
  user = config.core.username;
in
  lib.mkIf (!config.core.bareMinimum) {
    home-manager.users.${user} = {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        extraPackages = with pkgs; [
          # LSP servers
          lua-language-server
          gopls
          typescript-language-server
          vscode-langservers-extracted
          tailwindcss-language-server
          bash-language-server
          yaml-language-server
          terraform-ls

          # Formatters
          stylua
          prettierd
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
        ];
      };
    };
  }
