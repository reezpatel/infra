{self, ...}: {
  flake.modules.homeManager.editor.imports = with self.modules.homeManager; [
    nvim
  ];
}
