{
  inputs,
  self,
  ...
}: let
  system = "aarch64-linux";
in {
  flake.nixosConfigurations.rpi1 = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    modules = [
      inputs.home-manager.nixosModules.home-manager

      self.nixosModules.config
      self.nixosModules.system
      self.nixosModules.shellAlias
      self.nixosModules.shellFunctions
      self.nixosModules.home_assistant

      self.nixosModules.commonPackages
      self.nixosModules.rpi

      {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "rpi1";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

        fileSystems = {
          "/" = {
            device = "/dev/disk/by-label/NIXOS_SD";
            fsType = "ext4";
          };
        };

        system.stateVersion = "26.05";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "before-hm";

          users.reezpatel = {...}: {
            home = {
              stateVersion = "26.05";
            };

            imports = [
              inputs.agenix.homeManagerModules.default

              self.homeModules.zsh
              self.homeModules.vim
              self.homeModules.git
              self.homeModules.autojump
            ];
          };
        };
      }
    ];
  };
}
