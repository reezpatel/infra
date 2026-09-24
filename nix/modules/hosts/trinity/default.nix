# trinity (skull @ 192.168.2.2) — monitoring hub, git host, twodb node.
# 2TB Intel NVMe (disko) → /workspace, owned by the primary user.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.trinity = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      server

      samba
      twodb-node
      monitoring-server

      # Host-specific
      inputs.disko.nixosModules.disko
      ./_disko.nix
      ./_hardware-configuration.nix

      # Identity
      ({config, ...}: {
        hostname = "trinity";

        twodb.node.root = "/workspace";

        systemd.tmpfiles.rules = [
          "d /workspace 0775 ${config.username} users -"
        ];
      })
    ];
  };
}
