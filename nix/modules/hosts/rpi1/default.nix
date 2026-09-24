# rpi1 — first fleet node on full network boot (Pi 4, serial b4f64b8d):
# firmware over TFTP from divergent, root on iSCSI LUN rpi-1.img.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.rpi1 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      base
      rpi-netboot
      home
      twodb-node

      # Identity
      ({ config, ... }: {
        hostname = "rpi1";

        netboot = {
          serverIp = "192.168.2.7";
          initiator = "iqn.2026-08.local.rpi-1:initiator";
          targetName = "iqn.2026-08.local.infra:rpi-1";
        };

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
