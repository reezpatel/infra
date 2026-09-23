# rpi5 — fleet node on full network boot (Pi 4):
# firmware over TFTP from divergent, root on iSCSI LUN rpi-5.img.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.rpi5 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      base
      rpi-netboot
      home

      # Identity
      ({config, ...}: {
        hostname = "rpi5";

        netboot = {
          serverIp = "192.168.2.7";
          initiator = "iqn.2026-08.local.rpi-5:initiator";
          targetName = "iqn.2026-08.local.infra:rpi-5";
        };

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
