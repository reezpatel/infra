{ ... }: {
  # NetBird control plane — replaces the old headscale module (slayer only).
  #
  # Full self-hosted stack on nb.coupletruffle.com: management API, signal,
  # dashboard and a coturn relay. Authentication is delegated to a Pocket ID
  # OIDC provider on id.coupletruffle.com (passkey-based, single user).
  #
  # Post-deploy setup (one time):
  #   1. Point nb.coupletruffle.com and id.coupletruffle.com at slayer's IP.
  #   2. In Pocket ID (https://id.coupletruffle.com) create a PUBLIC OIDC
  #      client named `netbird` with PKCE enabled and redirect URIs:
  #        http://localhost:53000            (CLI login)
  #        https://nb.coupletruffle.com/auth
  #        https://nb.coupletruffle.com/silent-auth
  #   3. In the NetBird dashboard create a reusable setup key, then run:
  #        agenix -e secerts/netbird-setup-key.age
  #      and re-deploy the clients.
  flake.modules.nixos.netbird-server =
    { config, ... }:
    let
      domain = "nb.coupletruffle.com";
      idpDomain = "id.coupletruffle.com";
      idpUrl = "https://${idpDomain}";
    in
    {
      age.secrets.netbird-management-encryption-key = {
        file = ../../../../secerts/netbird-management-encryption-key.age;
        mode = "0400";
      };
      age.secrets.netbird-turn-secret = {
        file = ../../../../secerts/netbird-turn-secret.age;
        mode = "0400";
      };
      age.secrets.netbird-turn-password = {
        file = ../../../../secerts/netbird-turn-password.age;
        # Read by coturn's ExecStartPre, which runs as the service user.
        owner = "turnserver";
        group = "turnserver";
        mode = "0400";
      };
      age.secrets.pocket-id-encryption-key = {
        file = ../../../../secerts/pocket-id-encryption-key.age;
        mode = "0400";
      };

      # OIDC identity provider for the NetBird dashboard and CLI logins.
      services.pocket-id = {
        enable = true;
        credentials.ENCRYPTION_KEY = config.age.secrets.pocket-id-encryption-key.path;
        settings = {
          APP_URL = idpUrl;
          TRUST_PROXY = true;
          ANALYTICS_DISABLED = true;
        };
      };

      services.netbird.server = {
        enable = true;
        enableNginx = true;
        inherit domain;

        coturn = {
          enable = true;
          passwordFile = config.age.secrets.netbird-turn-password.path;
        };

        management = {
          # Single-account deployment: no org/tenant management needed.
          singleAccountModeDomain = "netbird";

          # Pocket ID discovery document; netbird auto-populates the auth
          # endpoints from it.
          oidcConfigEndpoint = "${idpUrl}/.well-known/openid-configuration";

          settings = {
            DataStoreEncryptionKey._secret = config.age.secrets.netbird-management-encryption-key.path;
            TURNConfig.Secret._secret = config.age.secrets.netbird-turn-secret.path;

            # Standalone (external IdP) path: the management API validates JWTs
            # against HttpConfig.AuthAudience, which has NO default here (the
            # "netbird-dashboard"/"netbird-cli" values only apply to netbird's
            # embedded IdP). Pocket ID emits access tokens with aud = client ID
            # when no API resource is requested, so both audiences = client ID.
            HttpConfig = {
              AuthAudience = "61fc42ef-bf0d-4756-bef8-00fa48eeaa6b";
              CLIAuthAudience = "61fc42ef-bf0d-4756-bef8-00fa48eeaa6b";
            };

            # No user/group sync into netbird (single user; peers enroll via
            # setup keys, the admin logs in via Pocket ID PKCE).
            IdpManagerConfig.ManagerType = "none";

            # CLI logins use PKCE (netbird up → browser → localhost:53000),
            # so the device authorization flow is not needed.
            DeviceAuthorizationFlow.Provider = "none";

            PKCEAuthorizationFlow.ProviderConfig = {
              # Pocket ID auto-generates client IDs (not editable in v2.13);
              # this is the `netbird` client created there.
              Audience = "61fc42ef-bf0d-4756-bef8-00fa48eeaa6b";
              ClientID = "61fc42ef-bf0d-4756-bef8-00fa48eeaa6b";
              Scope = "openid profile email offline_access";
            };
          };
        };

        dashboard.settings = {
          AUTH_AUTHORITY = idpUrl;
          AUTH_CLIENT_ID = "61fc42ef-bf0d-4756-bef8-00fa48eeaa6b";
          AUTH_AUDIENCE = "61fc42ef-bf0d-4756-bef8-00fa48eeaa6b";
          AUTH_SUPPORTED_SCOPES = "openid profile email offline_access";
          # The dashboard defaults to hash-based callbacks (/#callback).
          # These are PATHS appended to the dashboard origin (full URLs get
          # doubled), pinned so they match what is registered in Pocket ID.
          AUTH_REDIRECT_URI = "/auth";
          AUTH_SILENT_REDIRECT_URI = "/silent-auth";
        };
      };

      # TLS best practices (modern protocols/ciphers) for the public vhosts.
      services.nginx.recommendedTlsSettings = true;

      # The netbird nginx vhosts (management/signal/dashboard all share
      # `domain`) don't configure TLS themselves.
      services.nginx.virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          add_header Strict-Transport-Security "max-age=31536000" always;
        '';
      };

      services.nginx.virtualHosts.${idpDomain} = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          add_header Strict-Transport-Security "max-age=31536000" always;
        '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:1411";
          proxyWebsockets = true;
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "headscale@reezpatel.com";
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
