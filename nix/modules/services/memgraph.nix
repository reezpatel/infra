{...}: {
  # Memgraph — graph DB backing twodb (Bolt on 7687, neo4j-driver compatible).
  #
  # Not packaged in nixpkgs, so it runs as a rootful podman container
  # (same pattern as the waha service). State lives in the named podman
  # volume `memgraph-data`.
  #
  # Loopback-only publish: memgraph ships with NO auth by default and its
  # only consumer (twodb-server) is co-located on slayer — unlike the old
  # neo4j module it is deliberately NOT opened on the mesh interface. For
  # remote access (Memgraph Lab / mgconsole):
  #   ssh -L 7687:127.0.0.1:7687 slayer
  flake.modules.nixos.memgraph = {
    lib,
    pkgs,
    ...
  }: let
    memgraphImage = "docker.io/memgraph/memgraph:latest";
  in {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    systemd.services.memgraph = {
      description = "Memgraph graph database";
      after = [
        "network-online.target"
        "podman.socket"
      ];
      requires = ["podman.socket"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStartPre = "-${lib.getExe pkgs.podman} rm -f memgraph";
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.podman)
          "run"
          "--rm"
          "--pull=missing"
          "--name"
          "memgraph"
          "-p"
          "127.0.0.1:7687:7687"
          "-v"
          "memgraph-data:/var/lib/memgraph"
          (lib.escapeShellArg memgraphImage)
          # The container's entrypoint is the memgraph binary; everything
          # after the image is passed to it as flags.
          "--also-log-to-stderr"
        ];
        ExecStop = "${lib.getExe pkgs.podman} stop memgraph";
        Restart = "always";
        RestartSec = "10s";
        TimeoutStopSec = "70s";
      };
    };
  };
}
