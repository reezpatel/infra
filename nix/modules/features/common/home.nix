{
  inputs,
  self,
  ...
}: let
  sharedSettings = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-hm";
  };
in {
  # Aspect: core (homeManager) — every user on every host: agenix secrets.
  # Wired automatically into the primary user by the `home` aspect below.
  flake.modules.homeManager.core.imports = [
    inputs.agenix.homeManagerModules.default
  ];

  flake.modules.nixos.home = {config, ...}: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default
    ];

    home-manager =
      sharedSettings
      // {
        users.${config.username} = {
          home.stateVersion = "26.05";
          imports = [self.modules.homeManager.core];
        };
      };
  };

  flake.modules.darwin.home = {config, ...}: {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.agenix.darwinModules.default
    ];

    home-manager =
      sharedSettings
      // {
        users.${config.username} = {
          home.username = config.username;
          home.homeDirectory = "/Users/${config.username}";
          home.stateVersion = "26.05";
          imports = [self.modules.homeManager.core];
        };
      };
  };
}
