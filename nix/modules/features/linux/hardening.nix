{...}: {
  flake.modules.nixos.hardening = {lib, ...}: {
    services.openssh.settings = {
      PermitRootLogin = lib.mkDefault "prohibit-password";
      X11Forwarding = lib.mkDefault false;
    };

    services.fail2ban.bantime-increment.enable = true;

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
