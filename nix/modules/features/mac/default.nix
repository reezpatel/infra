{self, ...}: {
  flake.modules.darwin.darwin-base.imports = with self.modules.darwin; [
    macos
    homebrew
    common-homebrew-packages
  ];
}
