{
  inputs,
  self,
  ...
}: let
  system = "x86_64-linux";
in {
  flake.nixosConfigurations.divine = inputs.nixpkgs.lib.nixosSystem {
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
      self.nixosModules.ollama

      {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "divine";
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
            mdadm
            lsof
          ];
        }
      )

      ({lib, ...}: {
        # Assemble mdadm RAID arrays at boot
        boot.swraid.enable = true;
        boot.swraid.mdadmConf = ''
          MAILADDR root
        '';

        fileSystems."/mnt/ssd" = lib.mkForce {
          device = "/dev/md/raid1-ssd1";
          fsType = "xfs";
          options = ["noatime" "nofail"];
        };

        services.nfs.server = {
          enable = true;
          exports = ''
            /mnt/ssd    192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
            /mnt/nvme1  192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
          '';
        };

        # NFS server should wait for mounts
        systemd.services.nfs-server = {
          after = ["mnt-ssd.mount" "mnt-nvme1.mount"];
          wants = ["mnt-ssd.mount" "mnt-nvme1.mount"];
        };
      })

      {
        fileSystems."/mnt/mergefs" = {
          device = "/mnt/weed/sda:/mnt/weed/sdb";
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
      }
    ];
  };
}
