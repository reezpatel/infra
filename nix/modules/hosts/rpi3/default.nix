# rpi3 — fleet node on full network boot (Pi 4):
# firmware over TFTP from divergent, root on iSCSI LUN rpi-3.img.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.rpi3 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      base
      rpi-netboot
      home
      twodb-node

      # Identity
      ({ config, ... }: {
        hostname = "rpi3";

        netboot = {
          serverIp = "192.168.2.7";
          initiator = "iqn.2026-08.local.rpi-3:initiator";
          targetName = "iqn.2026-08.local.infra:rpi-3";
        };

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
