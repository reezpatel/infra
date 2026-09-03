# trinity — monitoring hub (Prometheus/Loki/Grafana), git host, twodb.
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
      twodb
      monitoring-server

      # Host-specific
      ./_hardware-configuration.nix

      # Identity
      ({...}: {
        hostname = "trinity";
      })
    ];
  };
}
