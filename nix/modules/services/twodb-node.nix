{ inputs, ... }:
{
  # TwoDB node agent — connects this machine to the twodb server on slayer
  # over the NetBird mesh (the agent dials out and holds a streaming
  # connection, so nothing inbound is opened).
  #
  # Enable in a host with:
  #
  #   twodb-node
  #   ({ ... }: { twodb.node.root = "/workspace"; })   # optional
  #
  # Requires secerts/twodb-node-token-<hostname>.age — the token from
  # Settings → Machines → Add machine in the twodb web UI. Until the real
  # token is encrypted over the placeholder, the agent will connect but fail
  # authentication (harmless retry loop).
  flake.modules.nixos.twodb-node =
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
          # Public nginx endpoint (TLS). Port 3001 itself is never exposed
          # publicly — agents ride 443 like any other client. The server is
          # a public VPS anyway, so the mesh would only add DNS fragility;
          # if you ever want mesh-direct anyway:
          #   "http://slayer.netbird:3001" (or slayer's 100.64.x.x mesh IP)
          default = "https://app.twodb.io";
          description = "URL of the twodb server the agent connects to.";
        };

        root = lib.mkOption {
          type = lib.types.str;
          default = "/home/${config.username}";
          description = "Folder code sessions work in (TWODB_ROOT).";
        };
      };

      config = {
        # Per-machine token (Settings → Machines → Add machine). Placeholder
        # until re-encrypted: agenix -e secerts/twodb-node-token-<host>.age
        age.secrets.twodb-node-token = {
          file = ../../../secerts/twodb-node-token-${config.hostname}.age;
          owner = config.username;
          group = "users";
          mode = "0400";
        };

        systemd.services.twodb-node = {
          description = "TwoDB node agent";
          after = [
            "network-online.target"
            "netbird-default.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            TWODB_NODE_URL = cfg.serverUrl;
            # Read + trimmed at startup; the agent refuses to start if the
            # file is unreadable.
            TWODB_NODE_TOKEN_FILE = config.age.secrets.twodb-node-token.path;
            TWODB_ROOT = cfg.root;
          };
          serviceConfig = {
            ExecStart = "${inputs.twodb.packages.${pkgs.stdenv.hostPlatform.system}.twodb-node}/bin/twodb-node";
            Restart = "on-failure";
            # Primary user (not DynamicUser) so sessions can read/write the
            # project tree with normal ownership.
            User = config.username;
            Group = "users";
          };
        };
      };
    };
}
