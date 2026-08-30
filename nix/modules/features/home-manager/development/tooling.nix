{self, ...}: {
  # Feature: editor-tooling (homeManager) — formatters, linters and debuggers
  # consumed by editor integrations (conform/none-ls/dap in nvim, or the
  # zed/vscode equivalents). Pulled in automatically by the `nvim` module.
  flake.modules.homeManager.editor-tooling = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Formatters
      stylua
      prettierd
      prettier
      black
      gofumpt
      beautysh
      alejandra
      nixfmt

      # Linters
      markdownlint-cli
      eslint_d
      golangci-lint
      tflint

      # Go editor helpers (goimports, gorename, ...)
      gotools

      # Debugger (nvim-dap / vscode-go)
      delve
    ];
  };

  # Neovim gets the tooling automatically (lsp is pulled in via lsp.nix).
  flake.modules.homeManager.nvim.imports = [self.modules.homeManager.editor-tooling];
}
