# slayer — Contabo VPS: NetBird control plane, public databases, twodb server.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.slayer = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      base

      # Features
      netbird-server

      # Services
      postgresql
      memgraph
      twodb-server
      komodo-core

      # Host-specific
      ./_hardware-configuration.nix
      ./_networking.nix

      # Identity + VPS tuning
      ({config, ...}: {
        hostname = "slayer";

        monitoring.client.lokiUrl = "http://100.64.0.14:3100/loki/api/v1/push";

        # Scratch space owned by the admin user.
        systemd.tmpfiles.rules = [
          "d /data 0755 ${config.username} users -"
        ];

        # Wildcard cert for *.twodb.io via Cloudflare DNS-01 (moved here from
        # the removed twodb-apps module). Any *.twodb.io vhost can use it via
        # `useACMEHost = "twodb.io"`. (security.acme.acceptTerms/defaults.email
        # come from the netbird-server module.)
        age.secrets.cloudflare-dns-token.file = ../../../../secerts/cloudflare-dns-token.age;
        security.acme.certs."twodb.io" = {
          domain = "*.twodb.io";
          extraDomainNames = [ "twodb.io" ];
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns-token.path;
          group = config.services.nginx.group;
        };

        # Dispatch gateway (:6400) for two-runner agents on the NetBird mesh
        # (http://slayer.lan.nb:6400). Mesh-only — never on the public NIC;
        # Macs and humans go through nginx on 443.
        networking.firewall.interfaces."nb-default".allowedTCPPorts = [
          6400
          # Second postgres instance (already bound to slayer's NetBird IP),
          # mesh-only — alongside the host postgres on 5432 (postgresql module).
          5439
        ];

        # Default catch-all: everything that isn't an explicitly named vhost
        # (app.twodb.io → twodb-server, nb/id.coupletruffle.com → netbird)
        # lands here and is proxied to 127.0.0.1:6400. nginx prefers exact
        # server_name matches, so those three domains keep their routing.
        services.nginx.virtualHosts."catch-all" = {
          default = true;
          forceSSL = true;
          # Wildcard *.twodb.io cert (DNS-01, above) — no per-host HTTP-01.
          useACMEHost = "twodb.io";
          locations."/" = {
            proxyPass = "http://127.0.0.1:6400";
            proxyWebsockets = true;
            # Pass the original Host through (nginx's default is the
            # proxy_pass target, i.e. Host: 127.0.0.1:6400 — useless to a
            # multi-domain app) plus the usual forwarded trio. These must
            # live HERE at location level: proxyWebsockets already sets
            # Upgrade/Connection headers, and nginx only inherits
            # proxy_set_header from outer blocks when the location sets
            # none of its own.
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Proto https;
              proxy_read_timeout 86400s;
              proxy_send_timeout 86400s;
            '';
          };
        };
      })
    ];
  };
}
