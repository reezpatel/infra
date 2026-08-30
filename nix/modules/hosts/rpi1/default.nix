# rpi1 — Raspberry Pi node on the tailnet.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.rpi1 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      rpi-node
      home

      # Features
      home-assistant

      # Identity
      ({config, ...}: {
        hostname = "rpi1";

        fileSystems."/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
