{self, ...}: {
  # Feature: lsp (homeManager) — language servers shared by all editors.
  #
  # Pulled in automatically by the `nvim` module. A host that uses only
  # zed/vscode (no nvim) can import this module directly to get the servers.
  flake.modules.homeManager.lsp = {pkgs, ...}: {
    home.packages = with pkgs; [
      # others
      lua-language-server
      vscode-langservers-extracted
      bash-language-server
      yaml-language-server
      stylua
      beautysh
      markdownlint-cli
      sqld

      # javascript
      tailwindcss-language-server
      typescript-language-server
      prettierd
      prettier
      eslint_d

      # python
      black

      # golang
      gopls
      gotools
      delve
      gofumpt
      golangci-lint

      # terraform
      terraform-ls
      tflint

      # nix
      nil
      nixd
      alejandra
      nixfmt
    ];
  };

  # Neovim gets the language servers automatically.
  flake.modules.homeManager.nvim.imports = [self.modules.homeManager.lsp];
}
