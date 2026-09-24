# rpi2 — fleet node on full network boot (Pi 4, serial cf9a1868):
# firmware over TFTP from divergent, root on iSCSI LUN rpi-2.img.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.rpi2 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      base
      rpi-netboot
      home
      twodb-node

      # Identity
      ({ config, ... }: {
        hostname = "rpi2";

        netboot = {
          serverIp = "192.168.2.7";
          initiator = "iqn.2026-08.local.rpi-2:initiator";
          targetName = "iqn.2026-08.local.infra:rpi-2";
        };

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
