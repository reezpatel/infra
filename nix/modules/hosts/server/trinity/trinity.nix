{
  inputs,
  self,
  ...
}:
let
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations.trinity = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default

      ./_hardware-configuration.nix

      self.nixosModules.config
      self.nixosModules.system
      self.nixosModules.shellAlias
      self.nixosModules.shellFunctions

      self.nixosModules.commonPackages
      self.nixosModules.advancedPackages
      self.nixosModules.parsec

      self.nixosModules.samba
      self.nixosModules.tailscale
      self.nixosModules.twodb

      self.nixosModules.monitoringServer
      self.nixosModules.monitoringClient

      (
        {
          config,
          pkgs,
          ...
        }:
        {
          nixpkgs.config.allowUnfree = true;

          username = "reezpatel";
          hostname = "trinity";

          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGK+XhnFOsJjoHqNmJ/NMyASsCsz7bkFoj3UpEP0hVQc reezpatel@divine"
          ];

          system.stateVersion = "26.05";

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "before-hm";

            users.reezpatel = { ... }: {
              home = {
                stateVersion = "26.05";
              };

              imports = [
                inputs.agenix.homeManagerModules.default
                self.homeModules.zsh
                self.homeModules.tmux
                self.homeModules.vim
                self.homeModules.nvim
                self.homeModules.git
                self.homeModules.autojump
              ];
            };
          };
        }
      )
    ];
  };
}
