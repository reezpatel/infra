{...}: {
  moduleRegistry.nixos.headscale = {
    config,
    pkgs,
    ...
  }: let
    domain = "hs.coupletruffle.com";
    headscale-ui = pkgs.fetchzip {
      url = "https://github.com/gurucomputing/headscale-ui/releases/download/2026.03.17/headscale-ui.zip";
      hash = "sha256-+PgogmoY/lEo4cHN3Taf69xAnz7v/E6hsvHsoq+kX4M=";
      stripRoot = false;
    };
  in {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8085;

      settings = {
        server_url = "https://${domain}";

        dns = {
          magic_dns = true;
          base_domain = "ts.coupletruffle.com";
          nameservers.global = ["1.1.1.1" "8.8.8.8"];
        };

        ip_prefixes = [
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
        ];

        log.level = "info";

        unix_socket = "/run/headscale/headscale.sock";
        unix_socket_permission = "0770";
      };
    };

    environment.systemPackages = [pkgs.headscale];

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
          '';
        };
        locations."/web/" = {
          root = headscale-ui;
          tryFiles = "$uri $uri/ /web/index.html";
          extraConfig = ''
            add_header 'Access-Control-Allow-Origin' 'https://${domain}';
          '';
        };
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "headscale@reezpatel.com";
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
