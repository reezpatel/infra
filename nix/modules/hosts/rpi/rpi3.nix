{inputs, ...}: {
  flake.nixosConfigurations.rpi3 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
    ];
  };
}
