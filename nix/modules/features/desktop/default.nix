{self, ...}: {
  flake.modules.nixos.desktop.imports = with self.modules.nixos; [
    gui_base
    gui_apps

    kde

    leapp
    parsec

    helium
  ];
}
