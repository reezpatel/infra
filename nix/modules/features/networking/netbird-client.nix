{ ... }: {
  # NetBird mesh client — replaces the old tailscale module.
  #
  # Enrolls into the self-hosted NetBird management server on slayer
  # (nb.coupletruffle.com) using a reusable setup key. The key is created in
  # the NetBird dashboard (Peers → Setup Keys) and stored in
  # secerts/netbird-setup-key.age.
  flake.modules.nixos.netbird-client = { config, ... }: {
    age.secrets.netbird-setup-key = {
      file = ../../../../secerts/netbird-setup-key.age;
      mode = "0400";
    };

    services.netbird.clients.default = {
      # The nixpkgs module has no default for the listen port; 51820 is
      # netbird's standard WireGuard port.
      port = 51820;

      # Expose the WireGuard port (crypto-authenticated, safe to expose —
      # enables direct peer connections instead of relay fallback) and trust
      # the mesh interface so mesh-internal traffic (prometheus scrapes,
      # loki push, samba-over-mesh, ...) isn't blocked by the firewall.
      openFirewall = true;
      openInternalFirewall = true;

      # Automated login at service start using the setup key (loaded via
      # systemd credentials, so it never touches the Nix store).
      login.enable = true;
      login.setupKeyFile = config.age.secrets.netbird-setup-key.path;

      # netbird's Go config unmarshals ManagementURL as a url.URL object,
      # not a plain string (a string here makes the daemon fail to start).
      # The gRPC dialer needs an explicit port in Host.
      config.ManagementURL = {
        Scheme = "https";
        Host = "nb.coupletruffle.com:443";
        Path = "/";
      };
    };
  };
}
