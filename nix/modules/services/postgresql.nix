{ ... }: {
  flake.modules.nixos.postgresql = { pkgs, ... }: {
    # Credentials are NOT managed here. No initialScript: it only runs when the
    # data directory is first created, so it never applied to the existing
    # cluster and would silently do nothing on re-deploy. Roles are set
    # out-of-band instead, which is also how they survive a rebuild:
    #   sudo -u postgres psql -c "ALTER ROLE <role> WITH PASSWORD '<pw>';"
    # (root -> postgres works via the `local all postgres peer` rule below.)
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      enableTCPIP = true; # listen_addresses = "*"

      # Inserted above the default rules (peer for local sockets, scram-sha-256
      # for TCP on localhost). Restricted to the NetBird mesh (100.64.0.0/10):
      # the firewall only opens this port on the nb-default interface, and
      # pg_hba provides the second layer.
      authentication = ''
        host all all 100.64.0.0/10 scram-sha-256
      '';
    };

    services.prometheus.exporters.postgres = {
      enable = true;
      listenAddress = "0.0.0.0";
      port = 9187;
      runAsLocalSuperUser = true;
    };

    # Mesh-only: reachable via the NetBird interface (nb-default), closed on
    # public and LAN interfaces.
    networking.firewall.interfaces."nb-default".allowedTCPPorts = [
      5432 # postgres
      9187 # prometheus postgres exporter (scraped by trinity over the mesh)
    ];
  };
}
