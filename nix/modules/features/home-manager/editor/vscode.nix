{...}: {
  # Feature: vscode (homeManager) — Visual Studio Code via nixpkgs.
  #
  # Used on divine. The macs install VS Code as a homebrew cask instead
  # ("visual-studio-code"), so they don't import this module.
  flake.modules.homeManager.vscode = {...}: {
    programs.vscode.enable = true;
  };
}
