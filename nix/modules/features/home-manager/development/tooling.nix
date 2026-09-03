{...}: {
  # Feature: editor-tooling (homeManager) — formatters, linters and debuggers
  # consumed by editor integrations (conform/none-ls/dap in nvim, or the
  # zed/vscode equivalents). Pulled in automatically by the `nvim` module.
  flake.modules.homeManager.tooling = {pkgs, ...}: {
    home.packages = with pkgs; [
      autossh
      gh
      git-wt
    ];
  };
}
