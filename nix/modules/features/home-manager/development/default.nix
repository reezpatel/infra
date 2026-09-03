{self, ...}: {
  flake.modules.homeManager.development.imports = with self.modules.homeManager; [
    devops
    kitty
    lsp
    nvim
    runtimes
    tooling
    ghostty
  ];
}
