{...}: {
  moduleRegistry.nixos.tailscale = {config, ...}: {
    age.secrets.headscale-auth-key = {
      file = ../../../secerts/headscale-auth-key.age;
      mode = "0400";
    };

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.headscale-auth-key.path;
      extraUpFlags = [
        "--login-server=https://hs.coupletruffle.com"
        "--accept-routes"
      ];
    };
  };
}
