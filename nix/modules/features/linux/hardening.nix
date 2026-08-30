{ ... }: {
  # Feature: hardening (nixos) — baseline security hardening for every host.
  #
  # Wired into `linux-base`, so all hosts get it. Host-specific lockdown
  # (e.g. slayer's public-VPS rules) stays in the host directory.
  flake.modules.nixos.hardening = { lib, ... }: {
    # ── SSH ────────────────────────────────────────────────────────────
    # Key-only root (mkDefault so a host can still opt back in), and no X11
    # forwarding unless a host explicitly wants it.
    services.openssh.settings = {
      PermitRootLogin = lib.mkDefault "prohibit-password";
      X11Forwarding = lib.mkDefault false;
    };

    # Escalating fail2ban bans for repeat offenders (default is flat 10m).
    services.fail2ban.bantime-increment.enable = true;

    # ── Kernel/network hardening ───────────────────────────────────────
    boot.kernel.sysctl = {
      # Drop spoofed packets (strict reverse-path filtering)
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # No ICMP redirects or source-routed packets
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      # Ignore broadcast pings and bogus error responses
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    };
  };
}
