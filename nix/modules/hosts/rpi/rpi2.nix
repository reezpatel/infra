{inputs, ...}: {
  flake.nixosConfigurations.rpi2 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
    ];
  };
}
