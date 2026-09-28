{ inputs, ... }:
{
  # TwoDB server — runs on slayer. Web UI at / + API under /api in one
  # process (port 3001); state in postgres + memgraph (Kysely migrations run
  # via ExecStartPre on every boot).
  #
  # Exposure:
  #   - Humans: nginx vhost https://app.twodb.io → 127.0.0.1:3001 (ACME).
  #   - Runner agents: NetBird mesh only — port 3001 is opened exclusively on
  #     the nb-default interface, never publicly.
  #
  # Secrets (one time): BETTER_AUTH_SECRET goes in the environmentFile, not
  # the world-readable store:
  #   agenix -e secerts/twodb-server-env.age
  # with content:  BETTER_AUTH_SECRET=<openssl rand -hex 32>
  #
  # Post-deploy (one time):
  #   1. Point app.twodb.io at slayer's public IP (147.93.171.18) so ACME
  #      can issue the cert.
  #   2. Open https://app.twodb.io — register a user, create an organization.
  #   3. Settings → Runners — create an access key per runner machine, then:
  #        agenix -e secerts/twodb-node-token-<host>.age
  #      and re-deploy that host.
  flake.modules.nixos.twodb-server =
    { config, lib, pkgs, ... }:
    {
      imports = [ inputs.twodb.nixosModules.default ];

      # Holds BETTER_AUTH_SECRET (see header). systemd reads EnvironmentFile
      # as root before dropping to the DynamicUser, so the default agenix
      # root:0400 perms are fine.
      age.secrets.twodb-server-env.file = ../../../secerts/twodb-server-env.age;

      services.twodb-server = {
        enable = true;
        package = inputs.twodb.packages.${pkgs.stdenv.hostPlatform.system}.twodb-server; # native systemd mode; null = GHCR container
        port = 3001;
        environment = {
          # Unix socket + the trust rule below. The user is explicit: with a
          # userless URL the driver falls back to the OS user, which for a
          # DynamicUser unit is the unit name ("twodb-server") — a role that
          # doesn't exist. (Peer auth can't identify dynamic users; single-
          # host, no network exposure — postgres itself stays mesh-only per
          # the postgresql service module.)
          TWODB_DATABASE_URL = "postgres://twodb@/twodb?host=/run/postgresql";
          # Memgraph runs on the same host (memgraph service module) and
          # publishes Bolt on loopback only.
          MEMGRAPH_URL = "bolt://127.0.0.1:7687";
          # Public origin (the nginx vhost below). better-auth issues session
          # cookies/magic links against it and passkeys bind to the rpID.
          BETTER_AUTH_URL = "https://app.twodb.io";
          PASSKEY_RP_ID = "app.twodb.io";
        };
        environmentFile = config.age.secrets.twodb-server-env.path;
      };

      # The upstream unit only waits for network-online; make sure the
      # databases are up first. Migrations are gone (8892cd8) — the server
      # self-bootstraps its schema on startup (lib/schema.ts, idempotent DDL).
      systemd.services.twodb-server = {
        after = [
          "postgresql.service"
          "memgraph.service"
        ];
      };

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

      # Runner agents only: reachable over the mesh, closed on the public
      # interface (humans go through nginx on 443).
      networking.firewall.interfaces."nb-default".allowedTCPPorts = [ 3001 ];

      services.nginx.virtualHosts."app.twodb.io" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3001";
          # Code sessions / runner + assistant sockets stream over websockets.
          proxyWebsockets = true;
        };
      };
    };
}
