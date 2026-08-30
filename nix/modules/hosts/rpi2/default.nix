# rpi2 — Raspberry Pi node on the tailnet.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.rpi2 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      rpi-node
      home

      # Identity
      ({config, ...}: {
        hostname = "rpi2";
        users.users.reezpatel.linger = true;

        fileSystems."/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
          openclaw
        ];
      })
    ];
  };
}
