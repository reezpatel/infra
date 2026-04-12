{inputs, ...}: {
  flake.nixosConfigurations.buttercup = inputs.nixpkgs.lib.nixosSystem {
    modules = [
    ];
  };
}
