{inputs, ...}: {
  flake.nixosConfigurations.rpi5 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
    ];
  };
}
