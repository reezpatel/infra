{ ... }: {
  moduleRegistry.nixos.postgresql = { pkgs, ... }: {
    # Default credentials: postgres / postgres (TCP, scram-sha-256).
    # The password is only applied on first cluster init (initialScript runs
    # when the data directory is created), so it can be changed later via CLI:
    #   sudo -u postgres psql -c "ALTER ROLE postgres WITH PASSWORD '<new>';"
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      enableTCPIP = true; # listen_addresses = "*"

      initialScript = pkgs.writeText "postgres-init" ''
        ALTER ROLE postgres WITH PASSWORD 'postgres';
      '';

      # Inserted above the default rules (peer for local sockets, scram-sha-256
      # for TCP on localhost). This host is intentionally exposed to the
      # internet (firewall is disabled host-wide), so allow password auth from
      # anywhere. CHANGE THE DEFAULT PASSWORD IMMEDIATELY after first deploy.
      authentication = ''
        host all all 0.0.0.0/0 scram-sha-256
        host all all ::/0 scram-sha-256
      '';
    };

    services.prometheus.exporters.postgres = {
      enable = true;
      listenAddress = "0.0.0.0";
      port = 9187;
      runAsLocalSuperUser = true;
    };

    # NOTE: networking.firewall.enable is false on slayer, so these are
    # no-ops today (everything is reachable). Kept so the ports stay correct
    # if the firewall is ever enabled.
    networking.firewall.allowedTCPPorts = [
      5432 # postgres
      9187 # prometheus postgres exporter
    ];
  };
}
