{self, ...}: {
  flake.modules.nixos.common.imports = with self.modules.nixos; [
    core
    common-packages
    environment
    home
  ];

  flake.modules.darwin.common.imports = with self.modules.darwin; [
    core
    common-packages
    environment
    home
  ];
}
