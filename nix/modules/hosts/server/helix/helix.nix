{
  inputs,
  self,
  ...
}: let
  system = "x86_64-linux";
in {
  flake.nixosConfigurations.helix = inputs.nixpkgs.lib.nixosSystem {
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

      self.nixosModules.tailscale
      self.nixosModules.kde
      self.nixosModules.helium

      {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "helix";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

        system.stateVersion = "26.05";

        systemd.services.NetworkManager-wait-online.enable = false;

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
              self.homeModules.tmux
              self.homeModules.vim
              self.homeModules.nvim
              self.homeModules.git
              self.homeModules.autojump
              self.homeModules.opencode
              self.homeModules.zed
              self.homeModules.ghostty
            ];
          };
        };
      }
    ];
  };
}
