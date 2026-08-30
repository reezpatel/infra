{self, ...}: {
  # Feature: lsp (homeManager) — language servers shared by all editors.
  #
  # Pulled in automatically by the `nvim` module. A host that uses only
  # zed/vscode (no nvim) can import this module directly to get the servers.
  flake.modules.homeManager.lsp = {pkgs, ...}: {
    home.packages = with pkgs; [
      lua-language-server
      typescript-language-server
      vscode-langservers-extracted
      tailwindcss-language-server
      bash-language-server
      yaml-language-server
      gopls
      terraform-ls

      # nix (also picked up by Zed's language server integration via user PATH)
      nil
      nixd
    ];
  };

  # Neovim gets the language servers automatically.
  flake.modules.homeManager.nvim.imports = [self.modules.homeManager.lsp];
}
