# trinity — monitoring hub (Prometheus/Loki/Grafana), git host, twodb.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.trinity = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      server
      home

      # Features
      samba
      twodb
      monitoring-server

      # Host-specific
      ./_hardware-configuration.nix

      # Identity
      ({config, ...}: {
        hostname = "trinity";

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
          nvim
          runtimes
          devops
          ollama
        ];
      })
    ];
  };
}
