# vixen — media services host (jellyfin/immich/stash/forgejo), offsite backup source.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.vixen = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      server
      home

      # Features
      nvidia
      samba
      webdav
      rclone-sync
      jellyfin
      immich
      stash
      forgejo
      transmission
      waha

      # Host-specific
      inputs.disko.nixosModules.disko
      ./_disko.nix
      ./_hardware-configuration.nix
      ./_storage.nix

      # Identity + service configuration
      (
        {
          config,
          pkgs,
          ...
        }: {
          hostname = "vixen";

          nvidiaGpu.enableCuda = true;
          stash.forceCuda = true;

          services.rcloneSync = {
            enable = true;
            source = "/mnt/mergefs";
            interval = "*-*-* 00/6:00:00";
            snapshotRetention = "30d";
            targets = [
              {
                name = "divine";
                host = "divine";
                user = "root";
                path = "/mnt/mergefs";
              }
              {
                name = "muse";
                host = "muse";
                user = "root";
                path = "/mnt/mergefs";
              }
            ];
          };

          virtualisation.docker = {
            enable = true;
            enableOnBoot = true;
            autoPrune.enable = true;
          };

          environment.systemPackages = with pkgs; [
            ffmpeg-full
          ];

          home-manager.users.${config.username}.imports = with self.modules.homeManager; [
            shell
            nvim
            runtimes
            devops
            ollama
          ];
        }
      )
    ];
  };
}
