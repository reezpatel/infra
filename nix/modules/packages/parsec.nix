{...}: let
  parsecModule = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # Simply add parsec-bin to all Linux systems
    environment.systemPackages = lib.mkIf pkgs.stdenv.isLinux [
      pkgs.parsec-bin
    ];
    
    # On NixOS, open firewall ports for Parsec when firewall is enabled
    networking.firewall = lib.mkIf (pkgs.stdenv.isLinux && config.networking.firewall.enable) {
      # Parsec uses these ports:
      # - 8000-8040/tcp for client connections
      # - 5353/udp for discovery
      # - 8000-8040/udp for streaming
      allowedTCPPortRanges = [
        { from = 8000; to = 8040; }
      ];
      allowedUDPPorts = [ 5353 ];
      allowedUDPPortRanges = [
        { from = 8000; to = 8040; }
      ];
    };
  };
in {
  # Register the module only for NixOS since parsec-bin is Linux-only
  moduleRegistry.nixos.parsec = parsecModule;
}