{ inputs, ... }:
{
  # TwoDB runner — connects this machine to the twodb server on slayer as a
  # code/terminal execution surface. The runner dials out (outbound
  # WebSocket), so nothing inbound is opened.
  #
  # Enable in a host with:
  #
  #   twodb-runner
  #
  # One shared access key for ALL runners (Settings → Runners in the twodb
  # web UI): secerts/twodb-runner-key.age holding TWODB_RUNNER_KEY=twr_…
  #
  # Native mode is the default (upstream package per host system, incl.
  # macos-arm64 with its own node-pty build). Upstream runs the runner as
  # DynamicUser / root-launchd — we override to the primary user so code
  # sessions read/write the project tree with normal ownership (same
  # rationale as the old twodb-node agent). Set
  # `services.twodb-runner.package = null;` for the GHCR container instead.
  flake.modules.nixos.twodb-runner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.twodb.nixosModules.default ];

      age.secrets.twodb-runner-key = {
        file = ../../../secerts/twodb-runner-key.age;
        owner = config.username;
        group = "users";
        mode = "0400";
      };

      services.twodb-runner = {
        enable = true;
        # Pin explicitly: upstream's default reads config.nixpkgs.hostPlatform,
        # which isn't defined on hosts whose hardware-configuration doesn't
        # set it (the netboot rpis) — pkgs.stdenv.hostPlatform always is.
        package = lib.mkDefault inputs.twodb.packages.${pkgs.stdenv.hostPlatform.system}.twodb-runner;
        # Public nginx endpoint (TLS) — the runner rides 443 like any other
        # client; port 3001 itself is mesh-only. The server is a public VPS
        # anyway, so the mesh would only add DNS fragility. Mesh-direct if
        # ever wanted: "http://slayer.netbird:3001" (or the 100.x mesh IP).
        serverUrl = "https://app.twodb.io";
        environmentFile = config.age.secrets.twodb-runner-key.path;
      };

      systemd.services.twodb-runner = {
        after = [ "netbird-default.service" ];
        serviceConfig = {
          # Primary user, not DynamicUser (see header).
          DynamicUser = lib.mkForce false;
          User = config.username;
          Group = "users";
        };
      };
    };

  flake.modules.darwin.twodb-runner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.twodb.darwinModules.default ];

      age.secrets.twodb-runner-key = {
        file = ../../../secerts/twodb-runner-key.age;
        owner = config.username;
        mode = "0400";
      };

      services.twodb-runner = {
        enable = true;
        # Pinned explicitly — see the nixos module above for why.
        package = lib.mkDefault inputs.twodb.packages.${pkgs.stdenv.hostPlatform.system}.twodb-runner;
        serverUrl = "https://app.twodb.io";
        # Deliberately NOT upstream's environmentFile: it builtins.readFile's
        # the secret at eval time — inlining it into the world-readable
        # launchd plist in the nix store, and failing first-time evals
        # before agenix has ever decrypted. The wrapper below exports the
        # key at process start instead.
      };

      launchd.daemons.twodb-runner.serviceConfig = {
        # Primary user, not root (see header).
        UserName = config.username;
        ProgramArguments = lib.mkForce [
          (toString (pkgs.writeShellScript "twodb-runner-start" ''
            set -a
            . ${config.age.secrets.twodb-runner-key.path}
            set +a
            exec ${config.services.twodb-runner.package}/bin/twodb-runner
          ''))
        ];
      };

      # launchd opens StandardOutPath AS the service user, and /var/log is
      # root-owned — without this the daemon fails to spawn with EX_CONFIG
      # (78) and never even creates the log file. Pre-create it user-owned.
      # (nix-darwin only runs a fixed set of activation script names, so this
      # must hang off postActivation — a custom name is silently ignored.)
      system.activationScripts.postActivation.text = lib.mkAfter ''
        /usr/bin/touch /var/log/twodb-runner.log
        /usr/sbin/chown ${config.username} /var/log/twodb-runner.log
      '';
    };
}
