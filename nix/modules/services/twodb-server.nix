{ ... }:
{
  # TwoDB server — runs on slayer as a rootful podman oci-container
  # (ghcr.io/reezpatel/twodb:latest). Web UI at / + API under /api in one
  # process (port 3001); state in postgres + memgraph. The server applies
  # its own migrations on startup (kysely, in-image) — no separate step.
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
  # (rootful podman reads the env-file as root, so default agenix root:0400
  # perms are fine.)
  #
  # Post-deploy (one time):
  #   1. Point app.twodb.io at slayer's public IP (147.93.171.18) so ACME
  #      can issue the cert.
  #   2. Open https://app.twodb.io — register a user, create an organization.
  #   3. Settings → Runners — create an access key per runner machine, then:
  #        agenix -e secerts/twodb-node-token-<host>.age
  #      and re-deploy that host.
  #
  # Note: the container image is NOT tied to the flake-locked twodb rev —
  # it tracks :latest. If the DB was ever migrated by newer code than the
  # running image (e.g. a stale :latest after a failed CI image build), the
  # server refuses to boot: "corrupted migrations: ... is missing".
  flake.modules.nixos.twodb-server =
    { config, ... }:
    {
      # Holds BETTER_AUTH_SECRET (see header).
      age.secrets.twodb-server-env.file = ../../../secerts/twodb-server-env.age;

      # Requires podman, which the memgraph module (a hard dependency of
      # twodb anyway) already enables.
      virtualisation.oci-containers.containers.twodb-server = {
        image = "ghcr.io/reezpatel/twodb:latest";
        autoStart = true;
        # oci-containers hardcodes --pull=missing otherwise: once an image
        # is cached under :latest it is NEVER refreshed, silently running
        # stale code forever. "newer" re-pulls when the registry has a newer
        # :latest and falls back to the local cache when it's unreachable.
        pull = "newer";

        # Host networking: reach postgres/memgraph on host loopback and
        # publish 3001 directly — no port mapping needed. Exposure posture is
        # unchanged: the NixOS firewall only allows 3001 on nb-default and
        # humans go through nginx on 443.
        extraOptions = [
          "--network=host"
          "--health-cmd=curl -fsS http://localhost:3001/api/health || exit 1"
        ];

        environment = {
          # Postgres over its unix socket, bind-mounted into the container
          # (below), so the `local twodb twodb trust` pg_hba rule keeps
          # working with no password in the URL and no extra secret. The user
          # in the URL is explicit: with a userless URL the driver falls back
          # to the container's OS user (root) — a role that doesn't exist.
          TWODB_DATABASE_URL = "postgres://twodb@/twodb?host=/run/postgresql";
          # Memgraph runs on the same host (memgraph service module) and
          # publishes Bolt on loopback only; reachable via the host network.
          MEMGRAPH_URL = "bolt://127.0.0.1:7687";
          # Public origin (the nginx vhost below). better-auth issues session
          # cookies/magic links against it and passkeys bind to the rpID.
          BETTER_AUTH_URL = "https://app.twodb.io";
          PASSKEY_RP_ID = "app.twodb.io";
        };
        environmentFiles = [ config.age.secrets.twodb-server-env.path ];

        # Postgres unix socket inside the container (see TWODB_DATABASE_URL).
        volumes = [ "/run/postgresql:/run/postgresql" ];
      };

      # The oci-containers unit only waits for network-online; make sure the
      # databases are up first.
      systemd.services.podman-twodb-server = {
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
          # nginx's default proxy_read_timeout is 60 s — idle WebSocket
          # connections (runners waiting for work) get severed, causing a
          # perpetual connect/register/1006-disconnect loop. 24 h matches
          # what recommendedProxySettings would set.
          extraConfig = ''
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
          '';
        };
      };
    };
}

