{ self, ... }: {
  flake.modules.nixos.linux-base.imports = with self.modules.nixos; [
    system
    firmware
    hardening
  ];
}
