{inputs, ...}: {
  moduleRegistry.nixos.pi = {
    imports = [inputs.pi.nixosModules.default];

    nix.settings = {
      extra-substituters = [
        "https://pi.cachix.org"
      ];
      extra-trusted-public-keys = [
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      ];
    };

    programs.pi.coding-agent.enable = true;
  };
}
