{...}: {
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
  #   UI:  http://slayer.netbird:9120
  #
  # Post-deploy setup (one time):
  #   1. Open http://slayer.netbird:9120 from any mesh peer and click Sign Up.
  #      `disable_user_registration` is on, so the FIRST account created wins
  #      and becomes admin; every later signup is rejected.
  #   2. Settings → Server Onboarding Keys → create a key, then:
  #        agenix -e secerts/komodo-onboarding-key.age
  #      (the file holds the raw key, no KEY= prefix), add it to secrets.nix,
  #      set `komodo.periphery.onboarding.enable = true` and redeploy the
  #      fleet — every host then registers itself as a Server automatically.
  #      Without it, create each Server by hand in the UI named after its
  #      hostname and leave the address blank (Periphery → Core mode).
  flake.modules.nixos.komodo-core = {
    lib,
    pkgs,
    ...
  }: let
    coreImage = "ghcr.io/moghtech/komodo-core:2";
    mongoImage = "docker.io/mongo:8";

    port = 9120;
    stateDir = "/var/lib/komodo";

    podman = lib.getExe pkgs.podman;

    # Reusable `podman run` wrapper: rootful, host network, restarted by
    # systemd rather than by podman's own restart policy.
    container = {
      name,
      image,
      extraArgs ? [],
      cmd ? [],
      after ? [],
      preStart ? [],
    }: {
      description = "Komodo ${lib.removePrefix "komodo-" name}";
      after =
        [
          "network-online.target"
          "podman.socket"
        ]
        ++ after;
      requires = ["podman.socket"];
      wants = ["network-online.target"] ++ after;
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStartPre = ["-${podman} rm -f ${name}"] ++ preStart;
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
          ++ [(lib.escapeShellArg image)]
          ++ cmd
        );
        ExecStop = "${podman} stop ${name}";
        Restart = "always";
        RestartSec = "10s";
        TimeoutStopSec = "70s";
      };
    };
  in {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
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
      after = ["komodo-mongo.service"];
      preStart = [
        (toString (pkgs.writeShellScript "komodo-core-jwt-secret" ''
          secret=${stateDir}/keys/jwt_secret
          if [ ! -s "$secret" ]; then
            umask 077
            ${lib.getExe pkgs.openssl} rand -hex 32 > "$secret"
          fi
        ''))
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
        # published publicly (NetBird single-account mode domain is
        # "netbird", see features/networking/netbird-server.nix).
        "-e"
        "KOMODO_HOST=http://slayer.netbird:${toString port}"
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
    networking.firewall.interfaces."nb-default".allowedTCPPorts = [port];

    # `km` — upstream CLI, handy for poking the API from the host itself.
    environment.systemPackages = [pkgs.komodo];
  };
}
