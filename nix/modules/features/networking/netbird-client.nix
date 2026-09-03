{...}: {
  flake.modules.nixos.netbird-client = {config, ...}: {
    age.secrets.netbird-setup-key = {
      file = ../../../../secerts/netbird-setup-key.age;
      mode = "0400";
    };

    services.netbird.clients.default = {
      port = 51820;

      openFirewall = true;
      openInternalFirewall = true;

      login.enable = true;
      login.setupKeyFile = config.age.secrets.netbird-setup-key.path;

      config.ManagementURL = {
        Scheme = "https";
        Host = "nb.coupletruffle.com:443";
        Path = "/";
      };
    };
  };
}
