{inputs, ...}: {
  flake.nixosConfigurations.rpi4 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
    ];
  };
}
