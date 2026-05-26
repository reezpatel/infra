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

      self.nixosModules.monitoringServer
      self.nixosModules.monitoringClient

      (
        {
          config,
          pkgs,
          ...
        }:
        let
          rustdeskPublicKey = "oMKZ6elB20ObNQsFypJ3Pff4qDmrCR2wIppm3vw0I74=";
          rustdeskPublicKeyFile = pkgs.writeText "rustdesk-id-ed25519.pub" rustdeskPublicKey;
          installRustdeskKeys = [
            "+${pkgs.coreutils}/bin/install -m 0600 -o rustdesk -g rustdesk ${config.age.secrets.rustdesk-id-ed25519.path} /var/lib/rustdesk/id_ed25519"
            "+${pkgs.coreutils}/bin/install -m 0644 -o rustdesk -g rustdesk ${rustdeskPublicKeyFile} /var/lib/rustdesk/id_ed25519.pub"
          ];
        in
        {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "trinity";
        age.secrets.rustdesk-id-ed25519 = {
          file = ../../../../../secerts/rustdesk-id-ed25519.age;
          owner = "rustdesk";
          group = "rustdesk";
          mode = "0400";
        };
        services.rustdesk-server = {
          enable = true;
          openFirewall = true;
          signal = {
            relayHosts = [ "trinity" ];
            extraArgs = [
              "-k"
              rustdeskPublicKey
            ];
          };
          relay.extraArgs = [
            "-k"
            rustdeskPublicKey
          ];
        };
        systemd.services.rustdesk-signal.serviceConfig.ExecStartPre = installRustdeskKeys;
        systemd.services.rustdesk-relay.serviceConfig.ExecStartPre = installRustdeskKeys;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

        system.stateVersion = "26.05";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "before-hm";

          users.reezpatel =
            { ... }:
            {
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
