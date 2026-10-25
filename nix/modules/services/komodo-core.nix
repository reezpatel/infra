{ ... }: {
  # Komodo Core — the single pane of glass over every containerised host in
  # the fleet (slayer only). Peripheries on the other machines dial *in* to
  # this process over NetBird; see services/komodo-periphery.nix.
  #
  # Why containers and not `pkgs.komodo`:
  #   nixpkgs builds the Rust binaries only — the web UI (`ui/dist`, served
  #   from `ui_path`, default /app/ui) and the bundled deno runtime used by
  #   Actions are assembled in upstream's Dockerfile. The periphery agent
  #   needs none of that and runs natively from pkgs.komodo; Core does, so it
  #   runs from the official image under rootful podman, exactly like the
  #   memgraph and waha services.
  #
  # Database: Core speaks the MongoDB wire protocol only (no sqlite/postgres
  # backend as of 2.x, hence no reuse of the postgres on this host). A plain
  # mongo container is used — bound to loopback with no auth, same reasoning
  # as the memgraph module: the only consumer is co-located and nothing is
  # published off-box.
  #
  # Exposure: NetBird mesh only. Both containers run with --network=host, so
  # Core's listener lands in the host's INPUT chain and the per-interface
  # firewall rule below is the whole story — no public vhost, no ACME.
  #   UI:  http://slayer.lan.nb:9120
  #
  # Post-deploy setup (one time):
  #   1. First boot creates the admin account from KOMODO_INIT_ADMIN_USERNAME
  #      / KOMODO_INIT_ADMIN_PASSWORD_FILE (upstream only honours them while
  #      the users collection is empty). Log in, then rotate the password in
  #      the UI — the env values become a no-op once a user exists.
  #   2. Server Onboarding Keys: the shared key lives in
  #      secerts/komodo-onboarding-key.age and `komodo.periphery.onboarding.enable`
  #      defaults to true — every host registers itself as a Server on first
  #      connect. Rotate by creating a new key in the UI and running:
  #        agenix -e secerts/komodo-onboarding-key.age
  #      (the file holds the raw key, no KEY= prefix). rpi7 is excluded (no
  #      host key in secrets.nix) — register it by hand in the UI.
  flake.modules.nixos.komodo-core =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Pinned to the nixpkgs komodo version (what every periphery in the
      # fleet runs): Core rejects mismatched peripheries ("Expected X.Y.Z"),
      # and the floating `:2` tag drifted a patch ahead once already. When
      # nixpkgs bumps komodo, the next slayer deploy pulls the matching
      # image (the container wrapper uses --pull=missing).
      coreImage = "ghcr.io/moghtech/komodo-core:${pkgs.komodo.version}";
      mongoImage = "docker.io/mongo:8";

      port = 9120;
      stateDir = "/var/lib/komodo";

      podman = lib.getExe pkgs.podman;

      # Reusable `podman run` wrapper: rootful, host network, restarted by
      # systemd rather than by podman's own restart policy.
      container =
        {
          name,
          image,
          extraArgs ? [ ],
          cmd ? [ ],
          after ? [ ],
          preStart ? [ ],
        }:
        {
          description = "Komodo ${lib.removePrefix "komodo-" name}";
          after = [
            "network-online.target"
            "podman.socket"
          ]
          ++ after;
          requires = [ "podman.socket" ];
          wants = [ "network-online.target" ] ++ after;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStartPre = [ "-${podman} rm -f ${name}" ] ++ preStart;
            ExecStart = lib.concatStringsSep " " (
              [
                podman
                "run"
                "--rm"
                "--pull=missing"
                "--network=host"
                "--name"
                name
              ]
              ++ extraArgs
              ++ [ (lib.escapeShellArg image) ]
              ++ cmd
            );
            ExecStop = "${podman} stop ${name}";
            Restart = "always";
            RestartSec = "10s";
            TimeoutStopSec = "70s";
          };
        };
    in
    {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      age.secrets.komodo-admin-password = {
        file = ../../../secerts/komodo-admin-password.age;
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d ${stateDir} 0700 root root -"
        # Core/Periphery Noise keypair + the generated jwt secret.
        "d ${stateDir}/keys 0700 root root -"
        # ResourceSync files, git repo cache and dated database backups.
        "d ${stateDir}/syncs 0700 root root -"
        "d ${stateDir}/repo-cache 0700 root root -"
        "d ${stateDir}/backups 0700 root root -"
      ];

      # Loopback-only, no auth — see header.
      systemd.services.komodo-mongo = container {
        name = "komodo-mongo";
        image = mongoImage;
        extraArgs = [
          "-v"
          "komodo-mongo-data:/data/db"
        ];
        # Everything after the image is handed to mongod by the entrypoint.
        cmd = [
          "--bind_ip"
          "127.0.0.1"
        ];
      };

      systemd.services.komodo-core = container {
        name = "komodo-core";
        image = coreImage;
        after = [ "komodo-mongo.service" ];
        preStart = [
          (toString (
            pkgs.writeShellScript "komodo-core-jwt-secret" ''
              secret=${stateDir}/keys/jwt_secret
              if [ ! -s "$secret" ]; then
                umask 077
                ${lib.getExe pkgs.openssl} rand -hex 32 > "$secret"
              fi
            ''
          ))
        ];
        extraArgs = [
          "--init"
          "-v"
          "${stateDir}/keys:/config/keys"
          "-v"
          "${stateDir}/syncs:/syncs"
          "-v"
          "${stateDir}/repo-cache:/repo-cache"
          "-v"
          "${stateDir}/backups:/backups"

          # Browser-facing origin. Mesh DNS name, since the UI is never
          # published publicly (peer DNS domain is "lan.nb", see
          # features/networking/netbird-server.nix).
          "-e"
          "KOMODO_HOST=http://slayer.lan.nb:${toString port}"
          "-e"
          "KOMODO_PORT=${toString port}"
          "-e"
          "KOMODO_TITLE=infra"

          # Host network -> mongo is simply on loopback.
          "-e"
          "KOMODO_DATABASE_ADDRESS=127.0.0.1:27017"

          # Username/password login. Registration closes after the first
          # account is created, which is the admin (see header).
          "-e"
          "KOMODO_LOCAL_AUTH=true"
          "-e"
          "KOMODO_DISABLE_USER_REGISTRATION=true"
          "-e"
          "KOMODO_MIN_PASSWORD_LENGTH=12"

          # Initial admin bootstrap: honoured only while the users collection
          # is empty, so this is a no-op once the account exists. Rotate the
          # password in the UI after first login.
          "-e"
          "KOMODO_INIT_ADMIN_USERNAME=${config.username}"
          "-e"
          "KOMODO_INIT_ADMIN_PASSWORD_FILE=/run/secrets/komodo-admin-password"
          "-v"
          "${config.age.secrets.komodo-admin-password.path}:/run/secrets/komodo-admin-password:ro"

          # Without a fixed secret Core mints a random one per start and every
          # session is dropped on restart/redeploy.
          "-e"
          "KOMODO_JWT_SECRET_FILE=/config/keys/jwt_secret"

          # Noise private key used to authenticate against peripheries;
          # generated on first run and TOFU-pinned by each agent thereafter.
          "-e"
          "KOMODO_PRIVATE_KEY=file:/config/keys/core.key"
        ];
      };

      # Mesh peers only. Nothing is opened on the public interface — slayer is
      # a VPS with a routable address, so this rule is the whole access control
      # story for both the UI and the inbound periphery websockets.
      networking.firewall.interfaces."nb-default".allowedTCPPorts = [ port ];

      # `km` — upstream CLI, handy for poking the API from the host itself.
      environment.systemPackages = [ pkgs.komodo ];
    };
}
