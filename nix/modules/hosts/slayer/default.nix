# slayer — Contabo VPS: NetBird control plane, public databases.
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
      neo4j

      # Host-specific
      ./_hardware-configuration.nix
      ./_networking.nix

      # Identity + VPS tuning
      ({...}: {
        hostname = "slayer";

        monitoring.client.lokiUrl = "http://100.64.0.14:3100/loki/api/v1/push";
      })
    ];
  };
}
