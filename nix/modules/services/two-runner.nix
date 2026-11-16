{ inputs, ... }:
{
  # two-runner — the NEW Dispatch machine-side agent (Go, apps/two-runner in
  # the twodb repo). Runs ALONGSIDE the old twodb-runner module (separate
  # option namespace: services.two-runner vs services.twodb-runner).
  #
  # Enable in a host with:
  #
  #   two-runner
  #
  # and, on hosts that should also host Firecracker microvms (divine, muse):
  #
  #   services.two-runner.microvm = true;
  #
  # Enrollment: ONE shared enrollment token (Dispatch → Enrollment tokens),
  # secerts/twodb-enroll.age holding the bare `twodbenroll_…` token. It is
  # only used until a machine has its own runner key; the first connect mints
  # a per-runner key persisted in the state dir, so the token can stay in
  # config without creating duplicates. Rotate:
  #   agenix -e secerts/twodb-enroll.age
  #
  # The dial-out is a single outbound WebSocket — nothing inbound is opened.
  flake.modules.nixos.two-runner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.twodb.nixosModules.two-runner ];

      # nixpkgs' cargo-setup-hook now exports AWS_LC_SYS_USE_SYSTEM=1 for every
      # Rust package, but firecracker vendors aws-lc-sys and has no system
      # AWS-LC to link — its build panics ("requires a system-installed
      # AWS-LC"). Opt firecracker out so it builds the vendored copy again.
      # Drop this once nixpkgs fixes the firecracker package.
      nixpkgs.overlays = [
        (_final: prev: {
          firecracker = prev.firecracker.overrideAttrs (_: {
            dontCargoUseSystemLibs = true;
          });
        })
      ];

      # Root-owned (agenix default): the unit reads it via systemd
      # LoadCredential, so no chown to the service user is needed.
      age.secrets.twodb-enroll = {
        file = ../../../secerts/twodb-enroll.age;
        mode = "0400";
      };

      services.two-runner = {
        enable = true;
        # Pin explicitly — upstream's default derives the package from
        # pkgs.stdenv.hostPlatform; same reasoning as twodb-runner.
        package = lib.mkDefault inputs.twodb.packages.${pkgs.stdenv.hostPlatform.system}.two-runner;
        # Mesh-direct: every NixOS host runs netbird-client, and slayer opens
        # 6400 on nb-default only. Plain http is fine — the mesh is encrypted.
        # NOTE: slayer's NetBird IP, NOT slayer.lan.nb. The gateway routes by
        # Host: a dotted hostname is looked up as a published-site domain
        # ("Nothing here yet" 404, so the runner's websocket handshake fails),
        # while IPs / bare names / localhost reach the console + runner-ws.
        gateway = "http://100.69.219.240:6400";
        enrollTokenFile = config.age.secrets.twodb-enroll.path;
        after = [ "netbird-default.service" ];
        # Primary user (like twodb-runner) so Dispatch commands see the normal
        # project tree with normal ownership, instead of a sandboxed
        # `two-runner` user.
        user = config.username;
        group = "users";
      };

      # microvm.enable (host sets `microvm = true;`): the upstream module now
      # provides the kernel, rootfs, static guest agent and TWO_RUNNER_FC_BIN,
      # and adds the kvm group to its own user. We run as the primary user, so
      # grant /dev/kvm to that user ourselves, and keep firecracker on the
      # system PATH for manual debugging.
      users.users.${config.username}.extraGroups =
        lib.mkIf config.services.two-runner.microvm.enable [ "kvm" ];
      environment.systemPackages =
        lib.mkIf config.services.two-runner.microvm.enable [ config.services.two-runner.microvm.firecracker ];
    };

  flake.modules.darwin.two-runner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.twodb.darwinModules.two-runner ];

      # No LoadCredential on launchd: the daemon reads the file directly as
      # its UserName, so the secret must be owned by that user.
      age.secrets.twodb-enroll = {
        file = ../../../secerts/twodb-enroll.age;
        owner = config.username;
        mode = "0400";
      };

      services.two-runner = {
        enable = true;
        package = lib.mkDefault inputs.twodb.packages.${pkgs.stdenv.hostPlatform.system}.two-runner;
        # Macs are on the NetBird mesh too: same mesh-direct gateway as the
        # NixOS hosts (slayer opens 6400 on nb-default only). IP, not the
        # dotted slayer.lan.nb name — see the NixOS block above.
        gateway = "http://100.69.219.240:6400";
        enrollTokenFile = config.age.secrets.twodb-enroll.path;
        user = config.username;
        # Default /var/lib/two-runner is unusual on macOS.
        stateDir = "/Users/${config.username}/.two-runner";
      };

      # Run as a launchd USER AGENT, not the upstream system daemon.
      #
      # System daemons live outside the GUI login session and cannot read the
      # user's login keychain, so tools Dispatch runs (gh, git credential
      # helpers, ...) that keep tokens there fail. A user agent runs in the
      # Aqua session, which unlocks the keychain at login — same reasoning and
      # pattern as twodb-runner. It also avoids the daemon's /var/log problem
      # (root:wheel 755, so a non-root UserName can't open its log: EX_CONFIG).
      #
      # Neutralise the upstream daemon so it never spawns (it would otherwise
      # fight the agent for the same runner key / state dir).
      launchd.daemons.two-runner.serviceConfig = {
        KeepAlive = lib.mkForce false;
        RunAtLoad = lib.mkForce false;
        ProgramArguments = lib.mkForce [ "/usr/bin/true" ];
      };

      launchd.user.agents.two-runner =
        let
          cfg = config.services.two-runner;
        in
        {
          serviceConfig = {
            Label = "dev.twodb.two-runner";
            # Same invocation as upstream's daemon.
            ProgramArguments = [
              "${cfg.package}/bin/two-runner"
              "--gateway"
              cfg.gateway
              "--name"
              cfg.name
              "--state"
              cfg.stateDir
              "--enroll-file"
              (toString cfg.enrollTokenFile)
            ]
            ++ cfg.extraArgs;
            EnvironmentVariables = {
              # Real $HOME is kept (upstream points it at stateDir) so tools
              # find ~/.config/gh, ~/.gitconfig, the keychain, etc.
              PATH = lib.concatStringsSep ":" [
                (lib.makeBinPath (
                  with pkgs;
                  [
                    bashInteractive
                    coreutils
                    findutils
                    gnugrep
                    gnused
                    git
                  ]
                  ++ cfg.extraPackages
                ))
                "/etc/profiles/per-user/${config.username}/bin"
                "/run/current-system/sw/bin"
                "/opt/homebrew/bin"
                "/usr/local/bin"
                "/usr/bin"
                "/bin"
                "/usr/sbin"
                "/sbin"
              ];
            };
            RunAtLoad = true;
            KeepAlive = true;
            # stateDir is user-owned 0700 (upstream activation script).
            StandardOutPath = "${cfg.stateDir}/two-runner.log";
            StandardErrorPath = "${cfg.stateDir}/two-runner.log";
          };
        };
    };
}
