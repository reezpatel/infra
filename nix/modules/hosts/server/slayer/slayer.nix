{
  inputs,
  self,
  ...
}:
let
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations.slayer = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.agenix.nixosModules.default

      ./_hardware-configuration.nix
      ./_networking.nix

      self.nixosModules.config
      self.nixosModules.system
      self.nixosModules.shellAlias
      self.nixosModules.shellFunctions

      self.nixosModules.commonPackages
      self.nixosModules.parsec
      self.nixosModules.headscale
      self.nixosModules.tailscale
      self.nixosModules.monitoringClient

      (
        {
          pkgs,
          lib,
          ...
        }:
        {
          boot.tmp.cleanOnBoot = true;
          zramSwap.enable = true;

          boot.loader.systemd-boot.enable = lib.mkForce false;
          boot.loader.grub.enable = lib.mkForce false;

          fileSystems."/boot" = lib.mkForce {
            device = "/dev/vda16";
            fsType = "vfat";
            options = [
              "noauto"
              "nofail"
            ];
            neededForBoot = false;
          };

          nixpkgs.config.allowUnfree = true;
          boot.kernelPackages = pkgs.linuxPackages_6_12;

          nix.settings = {
            substituters = [
              "https://cache.nixos.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ];
          };

          systemd.tmpfiles.rules = [
            "f /var/lib/systemd/linger/reezpatel 0644 root root -"
            "d /nix/var/nix/profiles/per-user/reezpatel 0755 reezpatel users -"
            "d /nix/var/nix/gcroots/per-user/reezpatel 0755 reezpatel users -"
            "d /home/reezpatel/.local 0755 reezpatel users -"
            "d /home/reezpatel/.local/state 0755 reezpatel users -"
            "d /home/reezpatel/.local/state/home-manager 0755 reezpatel users -"
            "d /home/reezpatel/.local/state/home-manager/gcroots 0755 reezpatel users -"
          ];

          username = "reezpatel";
          hostname = "slayer";
          monitoring.client.lokiUrl = "http://100.64.0.14:3100/loki/api/v1/push";
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

                systemd.user.startServices = false;

                imports = [
                  inputs.agenix.homeManagerModules.default
                  self.homeModules.git
                  self.homeModules.autojump
                  # self.homeModules.frp_server
                ];
              };
          };
        }
      )
    ];
  };
}
