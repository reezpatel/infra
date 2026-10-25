# rpi7 — fleet node on full network boot (Pi 4, serial 032354f6):
# firmware over TFTP from divergent, root on iSCSI LUN rpi-7.img.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.rpi7 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      base
      rpi-netboot
      home

      # Identity
      ({ config, ... }: {
        hostname = "rpi7";

        netboot = {
          serverIp = "192.168.2.7";
          initiator = "iqn.2026-08.local.rpi-7:initiator";
          targetName = "iqn.2026-08.local.infra:rpi-7";
          # Firmware-direct board (broken u-boot genet driver).
          firmwareBoot = true;
          # Not a recipient of secerts/netboot-push-key.age yet (host key
          # not in secrets.nix) — enable after adding it there + rekey.
          push.enable = false;
        };

        # Same missing host key: the shared Komodo onboarding key
        # (recipients = `all`) is not decryptable here. Register this
        # Server by hand in the UI, or drop this after adding rpi7 to
        # secrets.nix and rekeying.
        komodo.periphery.onboarding.enable = false;

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
