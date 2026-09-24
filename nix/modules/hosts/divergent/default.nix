# divergent — home server + fleet netboot/iSCSI server.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.divergent = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      base
      netboot-server

      # Host-specific
      inputs.disko.nixosModules.disko
      ./_disko.nix
      ./_hardware-configuration.nix

      ({ config, pkgs, ... }: {
        hostname = "divergent";

        # Keep the former TFTP address reachable while EEPROMs are migrated
        # from .68 to the new server address .7.
        networking.interfaces.eno1.ipv4.addresses = [
          {
            address = "192.168.2.68";
            prefixLength = 24;
          }
        ];

        # LIO target config (generated via targetcli, edit + saveconfig to extend)
        # All fileio backstores live under /workspace/iscsi — don't start the
        # target when the data disk isn't mounted (dead USB enclosure would
        # otherwise leave the target pointing at a root-fs path).
        services.target.enable = true;
        services.target.config = builtins.fromJSON (builtins.readFile ./_target-saveconfig.json);
        systemd.services.iscsi-target.unitConfig.RequiresMountsFor = [ "/workspace" ];

        # Fleet served over TFTP + PXE proxy DHCP. Pis netboot via
        # EEPROM (BOOT_ORDER network-first, TFTP_PREFIX=1 -> <serial>/ dirs).
        netboot-server = {
          enable = true;
          interface = "eno1";
          serverIp = "192.168.2.7";
          nodes = [
            {
              id = "rpi1";
              serial = "b4f64b8d";
              mac = "dc:a6:32:d8:81:bb";
              iqn = "iqn.2026-08.local.rpi-1:initiator";
              toplevel = self.nixosConfigurations.rpi1.config.system.build.toplevel;
            }
            {
              id = "rpi2";
              serial = "cf9a1868";
              mac = "88:a2:9e:22:2c:45";
              iqn = "iqn.2026-08.local.rpi-2:initiator";
              toplevel = self.nixosConfigurations.rpi2.config.system.build.toplevel;
            }
            {
              id = "rpi3";
              serial = "09068024";
              mac = "dc:a6:32:d8:9e:18";
              iqn = "iqn.2026-08.local.rpi-3:initiator";
              toplevel = self.nixosConfigurations.rpi3.config.system.build.toplevel;
            }
            {
              id = "rpi4";
              serial = "835480c9";
              mac = "e4:5f:01:ba:33:df";
              iqn = "iqn.2026-08.local.rpi-4:initiator";
              toplevel = self.nixosConfigurations.rpi4.config.system.build.toplevel;
            }
            {
              id = "rpi5";
              serial = "7ce2faed";
              mac = "e4:5f:01:82:ae:e4";
              iqn = "iqn.2026-08.local.rpi-5:initiator";
              # Bypass the failing U-Boot PXE handoff and boot directly
              # from rpi5's serial-prefixed TFTP directory.
              firmwareBoot = true;
              toplevel = self.nixosConfigurations.rpi5.config.system.build.toplevel;
            }
            {
              # flaky-u-boot board: firmware-direct boot from its serial dir
              id = "rpi6";
              serial = "3fbee5af";
              iqn = "iqn.2026-08.local.rpi-6:initiator";
              firmwareBoot = true;
              toplevel = self.nixosConfigurations.rpi6.config.system.build.toplevel;
            }
            {
              # second flaky-u-boot board (same 88:a2:9e batch): firmware-direct
              id = "rpi7";
              serial = "032354f6";
              mac = "88:a2:9e:22:2b:6d";
              iqn = "iqn.2026-08.local.rpi-7:initiator";
              firmwareBoot = true;
              toplevel = self.nixosConfigurations.rpi7.config.system.build.toplevel;
            }
          ];
        };

        # Builds aarch64 images for the rpis locally
        boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

        # For attaching fleet LUNs locally (installs, rescue, fsck).
        environment.systemPackages = [
          pkgs.openiscsi
          pkgs.gptfdisk
          pkgs.e2fsprogs
          pkgs.parted
        ];

        systemd.tmpfiles.rules = [
          "d /workspace 0755 ${config.username} users -"
        ];
      })
    ];
  };
}
