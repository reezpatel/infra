{ ... }: {
  flake.modules.nixos.twodb =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      twodbDir = "/var/lib/twodb";
      twodbImage = "ghcr.io/reezpatel/twodb:sha-cf067a8";

      # Rendered to ${twodbDir}/garage.toml by twodb-secrets-render.service,
      # which substitutes @RPC_SECRET@ from the agenix secret. Kept out of the
      # Nix store because it contains the cluster rpc_secret.
      garageTomlTemplate = pkgs.writeText "twodb-garage.toml" ''
        metadata_dir = "/var/lib/garage/meta"
        data_dir = "/var/lib/garage/data"
        db_engine = "sqlite"

        replication_factor = 1

        rpc_bind_addr = "127.0.0.1:3901"
        rpc_public_addr = "127.0.0.1:3901"
        rpc_secret = "@RPC_SECRET@"

        [s3_api]
        s3_region = "garage"
        api_bind_addr = "[::]:3900"
        root_domain = ".s3.garage.localhost"
      '';

      waitForDeps = pkgs.writeShellScript "twodb-wait-for-deps" ''
        for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
          if ${pkgs.postgresql_17}/bin/pg_isready -h 127.0.0.1 -p 5432 -U twodb -d twodb -q \
            && ${pkgs.netcat}/bin/nc -z 127.0.0.1 7687 \
            && ${pkgs.curl}/bin/curl -s -o /dev/null --max-time 2 http://127.0.0.1:3900; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
        echo "twodb dependencies not ready after 60s" >&2
        exit 1
      '';
    in
    {
      # Secret formats (files live in secerts/, registered in secerts/secrets.nix):
      #   twodb-postgres-password.age : single line, the postgres password
      #   twodb-garage-rpc-secret.age : single line, 64 hex chars (openssl rand -hex 32)
      #   twodb-s3-keys.age           : line 1 = S3 access key id, line 2 = S3 secret key
      age.secrets.twodb-postgres-password = {
        file = ../../../secerts/twodb-postgres-password.age;
        # Read by the postgresql-setup.service password sync, which runs as
        # the postgres user (and by the root render service).
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };
      age.secrets.twodb-garage-rpc-secret = {
        file = ../../../secerts/twodb-garage-rpc-secret.age;
        mode = "0400";
      };
      age.secrets.twodb-s3-keys = {
        file = ../../../secerts/twodb-s3-keys.age;
        mode = "0400";
      };

      # ------------------------------------------------------------------------
      # PostgreSQL (native)
      # ------------------------------------------------------------------------
      # twodb container binds PORT on all interfaces (host networking).
      # 5432: twodb's postgres - pg_hba explicitly allows LAN (192.168.2.0/24)
      # and mesh (100.64.0.0/10) clients; the global rule covers both.
      networking.firewall.allowedTCPPorts = [
        3001
        5432
      ];

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        enableTCPIP = true; # listen_addresses = "*"
        ensureDatabases = [ "twodb" ];
        ensureUsers = [
          {
            name = "twodb";
            ensureDBOwnership = true;
          }
        ];
        # Inserted above the default rules (peer for local sockets, password
        # auth for TCP). Host networking means the twodb container connects
        # from 127.0.0.1; the extra rules cover LAN and NetBird mesh clients.
        authentication = ''
          host twodb twodb 192.168.2.0/24 scram-sha-256
          host twodb twodb 100.64.0.0/10 scram-sha-256
        '';
      };

      # Keep the twodb role password in sync with the agenix secret. Runs as
      # the postgres user at the end of postgresql-setup.service, i.e. after
      # ensureUsers has created the role.
      systemd.services.postgresql-setup.script = lib.mkAfter ''
        password=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.twodb-postgres-password.path})
        psql -d postgres -v ON_ERROR_STOP=1 \
          -c "ALTER ROLE twodb WITH PASSWORD '$password'"
      '';

      # ------------------------------------------------------------------------
      # Garage (native, S3)
      # ------------------------------------------------------------------------
      users.groups.garage = { };
      users.users.garage = {
        isSystemUser = true;
        group = "garage";
      };
      users.users.${config.username}.extraGroups = [
        "docker"
        "garage"
      ];

      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        # Settings are NOT used for the real config: the module would render
        # them into the world-readable Nix store, which is where rpc_secret
        # would end up. Instead GARAGE_CONFIG_FILE (in the environmentFile)
        # points at the agenix-rendered ${twodbDir}/garage.toml.
        environmentFile = "${twodbDir}/garage.env";
      };

      systemd.services.garage = {
        after = [ "twodb-secrets-render.service" ];
        requires = [ "twodb-secrets-render.service" ];
        serviceConfig = {
          # Static user (set below) instead of DynamicUser so the group can
          # read the rendered garage.toml.
          DynamicUser = false;
          User = "garage";
          Group = "garage";
          # --single-node: auto-assign layout; --default-bucket: create the
          # access key + bucket from GARAGE_DEFAULT_* env vars (idempotent).
          ExecStart = lib.mkForce "${lib.getExe pkgs.garage_2} server --single-node --default-bucket";
        };
      };

      # ------------------------------------------------------------------------
      # Memgraph + twodb server (docker; memgraph is not packaged in nixpkgs,
      # twodb is only distributed as an OCI image)
      # ------------------------------------------------------------------------
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune.enable = true;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          memgraph = {
            image = "memgraph/memgraph:latest";
            autoStart = true;
            cmd = [ "--data-directory=/var/lib/memgraph/data" ];
            environment.MEMGRAPH_FLAGS = "--also-log-to-stderr";
            ports = [ "7687:7687" ];
            volumes = [ "memgraph-data:/var/lib/memgraph" ];
          };

          twodb = {
            image = twodbImage;
            autoStart = true;
            # Host networking: reaches postgres/memgraph/garage on 127.0.0.1
            # and binds PORT on all interfaces directly.
            extraOptions = [ "--network=host" ];
            environment = {
              PORT = "3001";
              MEMGRAPH_URL = "bolt://127.0.0.1:7687";
              MEMGRAPH_USER = "";
              MEMGRAPH_PASSWORD = "";
              MEMGRAPH_DATABASE = "memgraph";
              MEMGRAPH_POOL_SIZE = "50";
              POSTGRES_POOL_SIZE = "10";
              S3_ENDPOINT = "http://127.0.0.1:3900";
              S3_REGION = "garage";
              S3_BUCKET = "twodb";
              S3_FORCE_PATH_STYLE = "true";
            };
            # DATABASE_URL, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY
            environmentFiles = [ "${twodbDir}/twodb.env" ];
          };
        };
      };

      systemd.services.docker-twodb = {
        after = [
          "postgresql-setup.service"
          "garage.service"
          "docker-memgraph.service"
          "twodb-secrets-render.service"
        ];
        requires = [
          "postgresql-setup.service"
          "garage.service"
          "docker-memgraph.service"
          "twodb-secrets-render.service"
        ];
        # Oci-containers has no healthcheck gating; wait for the native
        # services to actually accept connections before starting twodb.
        serviceConfig.ExecStartPre = waitForDeps;
      };

      # ------------------------------------------------------------------------
      # Render env/config files from agenix secrets
      # ------------------------------------------------------------------------
      systemd.services.twodb-secrets-render = {
        description = "Render twodb env files and garage config from agenix secrets";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o root -g garage ${twodbDir}
          umask 077

          access_key=$(${pkgs.gnused}/bin/sed -n '1p' ${config.age.secrets.twodb-s3-keys.path})
          secret_key=$(${pkgs.gnused}/bin/sed -n '2p' ${config.age.secrets.twodb-s3-keys.path})
          password=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.twodb-postgres-password.path})

          # Env for the twodb container (read by the docker daemon as root).
          ${pkgs.coreutils}/bin/printf '%s\n' \
            "DATABASE_URL=postgres://twodb:$password@127.0.0.1:5432/twodb" \
            "S3_ACCESS_KEY_ID=$access_key" \
            "S3_SECRET_ACCESS_KEY=$secret_key" \
            > ${twodbDir}/twodb.env
          ${pkgs.coreutils}/bin/chmod 0400 ${twodbDir}/twodb.env

          # Env for garage (GARAGE_CONFIG_FILE is also picked up by the garage
          # CLI wrapper, so `garage status` etc. use the real config).
          ${pkgs.coreutils}/bin/printf '%s\n' \
            "GARAGE_CONFIG_FILE=${twodbDir}/garage.toml" \
            "GARAGE_DEFAULT_ACCESS_KEY=$access_key" \
            "GARAGE_DEFAULT_SECRET_KEY=$secret_key" \
            "GARAGE_DEFAULT_BUCKET=twodb" \
            > ${twodbDir}/garage.env
          ${pkgs.coreutils}/bin/chown root:garage ${twodbDir}/garage.env
          ${pkgs.coreutils}/bin/chmod 0440 ${twodbDir}/garage.env

          rpc_secret=$(${pkgs.coreutils}/bin/cat ${config.age.secrets.twodb-garage-rpc-secret.path})
          ${pkgs.gnused}/bin/sed "s|@RPC_SECRET@|$rpc_secret|" ${garageTomlTemplate} > ${twodbDir}/garage.toml
          ${pkgs.coreutils}/bin/chown root:garage ${twodbDir}/garage.toml
          ${pkgs.coreutils}/bin/chmod 0440 ${twodbDir}/garage.toml
        '';
      };
    };
}
