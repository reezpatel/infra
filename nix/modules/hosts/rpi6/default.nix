# rpi6 — fleet node on full network boot (Pi 4, serial 3fbee5af).
# This board's u-boot genet driver never transmits, so it boots
# FIRMWARE-DIRECT from its serial TFTP dir (see netboot-server nodes),
# skipping u-boot entirely. Root on iSCSI LUN rpi-6.img as usual.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.rpi6 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      base
      rpi-netboot
      home

      # Identity
      ({config, ...}: {
        hostname = "rpi6";

        netboot = {
          serverIp = "192.168.2.7";
          initiator = "iqn.2026-08.local.rpi-6:initiator";
          targetName = "iqn.2026-08.local.infra:rpi-6";
        };

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
