{
  inputs,
  self,
  ...
}: let
  system = "x86_64-linux";
in {
  flake.nixosConfigurations.muse = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.agenix.nixosModules.default

      ./_disko.nix
      ./_hardware-configuration.nix

      self.nixosModules.config
      self.nixosModules.system
      self.nixosModules.nvidia_gpu
      self.nixosModules.shellAlias
      self.nixosModules.shellFunctions

      self.nixosModules.commonPackages
      self.nixosModules.advancedPackages

      self.nixosModules.samba

      {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "muse";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

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
              self.homeModules.tmux
              self.homeModules.vim
              self.homeModules.nvim
              self.homeModules.git
              self.homeModules.autojump
              self.homeModules.fastfetch
            ];
          };
        };
      }

      (
        {pkgs, ...}: {
          environment.systemPackages = with pkgs; [
            mergerfs
            snapraid
          ];
        }
      )

      {
        fileSystems."/mnt/mergefs" = {
          device = "/mnt/weed/sda:/mnt/weed/sdb:/mnt/weed/sdd:/mnt/weed/sde";
          fsType = "fuse.mergerfs";
          options = [
            "defaults"
            "nofail"
            "allow_other"
            "use_ino"
            "cache.files=partial"
            "dropcacheonclose=true"
            "category.create=mfs" # place new files on disk with most free space
          ];
        };

        services.snapraid = {
          enable = true;

          parityFiles = [
            "/mnt/weed/sdf/snapraid.parity"
          ];

          # Content files: keep one on parity + one per data disk (redundancy)
          contentFiles = [
            "/var/snapraid.content"
            "/mnt/weed/sda/.snapraid.content"
            "/mnt/weed/sdb/.snapraid.content"
            "/mnt/weed/sdd/.snapraid.content"
            "/mnt/weed/sde/.snapraid.content"
            "/mnt/weed/sdf/.snapraid.content"
          ];

          dataDisks = {
            d1 = "/mnt/weed/sda";
            d2 = "/mnt/weed/sdb";
            d3 = "/mnt/weed/sdd";
            d4 = "/mnt/weed/sde";
          };

          exclude = [
            "*.unrecoverable"
            "/tmp/"
            "/lost+found/"
            "downloads/"
            "*.!sync"
          ];

          # Auto-sync schedule (runs nightly at 2am)
          sync.interval = "04:00";

          # Auto-scrub (verify data integrity, runs weekly)
          scrub.interval = "Mon *-*-* 03:00:00";
        };
      }
    ];
  };
}
