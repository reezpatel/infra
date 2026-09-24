{ inputs, ... }:
{
  # TwoDB node agent (macOS) — connects this machine to the twodb server
  # over the public HTTPS endpoint (Macs roam; the NetBird mesh may not
  # always be up). The agent dials out, nothing inbound is opened.
  #
  # Enable in a host with:
  #
  #   twodb-node
  #   ({ ... }: { twodb.node.root = "/Users/reezpatel/Workspace"; })  # optional
  #
  # Requires secerts/twodb-node-token-<hostname>.age — the token from
  # Settings → Machines → Add machine in the twodb web UI.
  flake.modules.darwin.twodb-node =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.twodb.node;
    in
    {
      options.twodb.node = {
        serverUrl = lib.mkOption {
          type = lib.types.str;
          default = "https://app.twodb.io";
          description = "URL of the twodb server the agent connects to.";
        };

        root = lib.mkOption {
          type = lib.types.str;
          default = "/Users/${config.username}";
          description = "Folder code sessions work in (TWODB_ROOT).";
        };
      };

      config = {
        # Per-machine token (Settings → Machines → Add machine).
        age.secrets.twodb-node-token = {
          file = ../../../secerts/twodb-node-token-${config.networking.hostName}.age;
          owner = config.username;
          mode = "0400";
        };

        launchd.daemons.twodb-node = {
          serviceConfig = {
            ProgramArguments = [
              "${inputs.twodb.packages.${pkgs.system}.twodb-node}/bin/twodb-node"
            ];
            EnvironmentVariables = {
              TWODB_NODE_URL = cfg.serverUrl;
              # Read + trimmed at startup; the agent refuses to start if the
              # file is unreadable.
              TWODB_NODE_TOKEN_FILE = config.age.secrets.twodb-node-token.path;
              TWODB_ROOT = cfg.root;
            };
            # Primary user so sessions read/write the project tree with
            # normal ownership (mirrors the NixOS module).
            UserName = config.username;
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/tmp/twodb-node.log";
            StandardErrorPath = "/tmp/twodb-node.log";
          };
        };
      };
    };
}
