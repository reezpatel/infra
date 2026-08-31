{...}: {
  flake.modules.nixos.parsec = {
    config,
    lib,
    pkgs,
    ...
  }: {
    environment.systemPackages =  [
      pkgs.parsec-bin
    ];

    networking.firewall = {
      # Parsec uses these ports:
      # - 8000-8040/tcp for client connections
      # - 5353/udp for discovery
      # - 8000-8040/udp for streaming
      allowedTCPPortRanges = [
        {
          from = 8000;
          to = 8040;
        }
      ];
      allowedUDPPorts = [5353];
      allowedUDPPortRanges = [
        {
          from = 8000;
          to = 8040;
        }
      ];
    };
  }
}
