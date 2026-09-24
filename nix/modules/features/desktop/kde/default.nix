{ self, ... }: {
  flake.modules.nixos.kde_desktop.imports = with self.modules.nixos; [
    kde
    kde_theme
    kde_shell
  ];
}
