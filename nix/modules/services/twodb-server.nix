{ inputs, ... }:
{
  # TwoDB server — runs on slayer. Web + API in one process (port 3001),
  # state in postgres + /var/lib/twodb (plugins are seeded into the database
  # on first boot).
  #
  # Exposure:
  #   - Humans: nginx vhost https://app.twodb.io → 127.0.0.1:3001 (ACME).
  #   - Node agents: NetBird mesh only — port 3001 is opened exclusively on
  #     the nb-default interface, never publicly.
  #
  # Post-deploy (one time):
  #   1. Point app.twodb.io at slayer's public IP (147.93.171.18) so ACME
  #      can issue the cert.
  #   2. Open https://app.twodb.io — register the admin passkey, run the
  #      first-run flow (vault + workspace).
  #   3. Settings → Machines → Add machine (one per node host), then:
  #        agenix -e secerts/twodb-node-token-<host>.age
  #      and re-deploy that host.
  flake.modules.nixos.twodb-server =
    { ... }:
    {
      imports = [ inputs.twodb.nixosModules.default ];

      services.twodb-server = {
        enable = true;
        port = 3001;
        # Unix socket + the trust rule below. The user is explicit: with a
        # userless URL the driver falls back to the OS user, which for a
        # DynamicUser unit is the unit name ("twodb-server") — a role that
        # doesn't exist. (Peer auth can't identify dynamic users; single-
        # host, no network exposure — postgres itself stays mesh-only per
        # the postgresql service module.)
        databaseUrl = "postgres://twodb@/twodb?host=/run/postgresql";
        extraEnvironment = {
          # Passkeys bind to the public origin (the nginx vhost below).
          TWODB_ADMIN_RP_ID = "app.twodb.io";
          TWODB_ADMIN_ORIGIN = "https://app.twodb.io";
        };
      };

      # The upstream unit only waits for network-online; make sure the
      # database is up first.
      systemd.services.twodb-server.after = [ "postgresql.service" ];

      services.postgresql = {
        ensureDatabases = [ "twodb" ];
        ensureUsers = [
          {
            name = "twodb";
            ensureDBOwnership = true;
          }
        ];
        authentication = ''
          local twodb twodb trust
        '';
      };

      # Node agents only: reachable over the mesh, closed on the public
      # interface (humans go through nginx on 443).
      networking.firewall.interfaces."nb-default".allowedTCPPorts = [ 3001 ];

      services.nginx.virtualHosts."app.twodb.io" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3001";
          # Code sessions stream over websockets.
          proxyWebsockets = true;
        };
      };
    };
}
