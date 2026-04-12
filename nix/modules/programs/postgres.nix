{...}: {
  moduleRegistry.nixos.postgresql = {
    config,
    pkgs,
    ...
  }: {
    config.services.postgresql = {
      enable = true;
      enableTCPIP = true;
      ensureDatabases = ["mydatabase"];
      authentication = pkgs.lib.mkOverride 10 ''
        #type database DBuser origin-address auth-method
        local all      all     trust
        # ... other auth rules ...

        # ipv4
        host  all      all     127.0.0.1/32   trust
        # ipv6
        host  all      all     ::1/128        trust

        #type database  DBuser  auth-method optional_ident_map
        local sameuser  all     peer        map=superuser_map


        #type database  DBuser  auth-method
        local all       all     trust
        host  sameuser    all     127.0.0.1/32 scram-sha-256
        host  sameuser    all     ::1/128 scram-sha-256
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE nixcloud WITH LOGIN PASSWORD 'nixcloud' CREATEDB;
        CREATE DATABASE nixcloud;
        GRANT ALL PRIVILEGES ON DATABASE nixcloud TO nixcloud;
      '';
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      postgres  postgres
           # Let other names login as themselves
           superuser_map      /^(.*)$   \1
      '';
      ensureUsers = [
        {
          name = "tootieapp";
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            password = "SCRAM-SHA-256$4096:lB4tguN+gvNVSqk0zGRPHQ==$zh48o1bb9tuRjvGQHh/CeobEyUI4u91rp0K9who8m3I=:mHxc6obGad8/g65+V3C84UQGHIK41Gfx32+xXSZiOss=";
          };
        }
      ];
    };

    # services.prometheus.exporters.postgres = {
    #     enable = true;
    #     listenAddress = "0.0.0.0";
    #     port = 9187;
    # };
  };
}
