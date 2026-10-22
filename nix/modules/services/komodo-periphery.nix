{...}: {
  # Komodo Periphery — the per-host agent behind the Komodo Core UI on
  # slayer. Imported by `base`, so every NixOS host in the fleet runs one;
  # the darwin hosts (ace, luffy) have no equivalent and stay out.
  #
  # Connection direction: OUTBOUND (v2 "Periphery -> Core"). The agent dials
  # Core over the NetBird mesh, which means:
  #   - nothing inbound is opened on any host (no :8120, no self-signed TLS),
  #   - the Core public key is trust-on-first-use pinned into
  #     /var/lib/komodo-periphery/keys/core.pub on the first handshake,
  #   - NAT'd / netbooted nodes work with zero per-host plumbing.
  # The payload is Noise-encrypted end to end, so plain http:// to Core is
  # fine — and it is riding WireGuard underneath regardless.
  #
  # Container runtime: podman, through its Docker-compatible API socket.
  # Komodo shells out to the `docker` CLI and talks the Docker API with
  # bollard; both honour DOCKER_HOST, so pointing them at
  # /run/podman/podman.sock gives Komodo full visibility of the podman
  # containers this repo already runs (memgraph, waha, komodo itself).
  # `legacyComposeCli` makes it call `docker-compose` as a standalone binary
  # instead of the `docker compose` plugin, which nixpkgs' docker CLI does
  # not bundle.
  #
  # Post-deploy: see the header of services/komodo-core.nix — create a Server
  # Onboarding Key in the UI, store it, and flip
  # `komodo.periphery.onboarding.enable` to let hosts self-register.
  flake.modules.nixos.komodo-periphery = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.komodo.periphery;
  in {
    options.komodo.periphery = {
      coreAddress = lib.mkOption {
        type = lib.types.str;
        default = "http://slayer.netbird:9120";
        description = ''
          Address of Komodo Core on the NetBird mesh. Scheme matters:
          http:// becomes ws://, a bare host becomes wss://.
        '';
      };

      onboarding.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Pass a Server Onboarding Key so this host registers itself as a
          Server in Komodo on first connect. Off by default because the key
          only exists after Core has been deployed and a human has created
          it in the UI — turning it on before
          `secerts/komodo-onboarding-key.age` exists breaks evaluation.

          Note: muse and rpi7 have no host key in secerts/secrets.nix yet, so
          they cannot decrypt the shared key. Either add them there and rekey,
          or leave this false on those two and create their Server by hand.
        '';
      };
    };

    config = {
      # Rootful podman + its Docker-compat API socket. Hosts that also run
      # dockerd (the `server` aspect) are unaffected: this adds a second
      # runtime rather than replacing theirs, and Komodo only ever sees the
      # podman side.
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      age.secrets.komodo-onboarding-key = lib.mkIf cfg.onboarding.enable {
        file = ../../../secerts/komodo-onboarding-key.age;
        owner = "komodo-periphery";
        group = "komodo-periphery";
        mode = "0400";
      };

      services.komodo-periphery = {
        enable = true;

        # Docker API via podman. Setting this also stops the upstream module
        # from pulling in dockerd on hosts that don't already have it.
        dockerHost = "unix:///run/podman/podman.sock";

        outbound = {
          coreAddress = cfg.coreAddress;
          # Must match the Server name in Komodo; the onboarding key creates
          # it under this name on first connect.
          connectAs = config.hostname;
          onboardingKeyFile = lib.mkIf cfg.onboarding.enable config.age.secrets.komodo-onboarding-key.path;
        };

        # Outbound-only: the inbound listener is already off (the module
        # derives server_enabled from coreAddress), so the self-signed cert
        # machinery is dead weight.
        inbound.ssl.enable = false;

        # `docker compose` is a CLI plugin that nixpkgs' docker package does
        # not ship; the standalone binary below is what we actually have.
        legacyComposeCli = true;

        # Without a filter the agent reports every bind mount, overlay and
        # tmpfs as a disk. One entry on the root filesystem gives the real
        # root disk size.
        includeDiskMounts = ["/etc/hostname"];
      };

      systemd.services.komodo-periphery = {
        after = ["podman.socket"];
        wants = ["podman.socket"];
        # Prepended to the module's own path (git + docker CLI).
        path = [pkgs.docker-compose];
      };

      # The module only grants the `docker` group, and only when it manages
      # dockerd itself. Reading /run/podman/podman.sock needs `podman`.
      users.users.${config.services.komodo-periphery.user}.extraGroups = ["podman"];

      # Only the CLI is needed — dockerd would be dead weight in the closure
      # of every host, and is especially unwelcome on the netbooted Pis.
      # Hosts that genuinely run dockerd set `virtualisation.docker.enable`
      # and this is skipped.
      virtualisation.docker.package = lib.mkIf (!config.virtualisation.docker.enable) pkgs.docker-client;
    };
  };
}
