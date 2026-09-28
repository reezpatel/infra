# slayer — Contabo VPS: NetBird control plane, public databases, twodb server.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.slayer = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      base

      # Features
      netbird-server

      # Services
      postgresql
      memgraph
      twodb-server

      # Host-specific
      ./_hardware-configuration.nix
      ./_networking.nix

      # Identity + VPS tuning
      ({config, ...}: {
        hostname = "slayer";

        monitoring.client.lokiUrl = "http://100.64.0.14:3100/loki/api/v1/push";

        # Scratch space owned by the admin user.
        systemd.tmpfiles.rules = [
          "d /data 0755 ${config.username} users -"
        ];
      })
    ];
  };
}
