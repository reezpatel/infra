{...}: {
  moduleRegistry.nixos.forgejo = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.forgejo;
    domain = "git.unpatch.in";
  in {
    age.secrets.forgejo-runner-token.file = ../../../secerts/forgejo-runner-token.age;
    age.secrets.forgejo-password = {
      file = ../../../secerts/forgejo-password.age;
      owner = cfg.user;
      group = cfg.group;
      mode = "0400";
    };

    services.forgejo = {
      enable = true;
      database.type = "sqlite3";
      stateDir = "/mnt/mergefs/programs/forgejo";

      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = domain;
          ROOT_URL = "https://${domain}";
          HTTP_PORT = 9965;
          SSH_PORT = lib.head config.services.openssh.ports;
        };

        service.DISABLE_REGISTRATION = true;

        actions = {
          ENABLED = true;
        };
      };
    };

    systemd.services.forgejo-state-dirs = {
      description = "Prepare Forgejo state directories";
      before = [
        "forgejo-secrets.service"
        "forgejo.service"
      ];
      requiredBy = [
        "forgejo-secrets.service"
        "forgejo.service"
      ];
      after = ["mnt-mergefs.mount"];
      requires = ["mnt-mergefs.mount"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        ${pkgs.coreutils}/bin/install -d -m 0750 -o ${cfg.user} -g ${cfg.group} \
          ${cfg.stateDir} \
          ${cfg.stateDir}/custom \
          ${cfg.stateDir}/custom/conf \
          ${cfg.stateDir}/data \
          ${cfg.stateDir}/data/lfs \
          ${cfg.stateDir}/repositories \
          ${cfg.stateDir}/dump
      '';
    };

    systemd.services.forgejo-secrets = {
      after = ["forgejo-state-dirs.service"];
      requires = ["forgejo-state-dirs.service"];
    };

    systemd.services.forgejo = {
      after = [
        "mnt-mergefs.mount"
        "forgejo-state-dirs.service"
      ];
      requires = [
        "mnt-mergefs.mount"
        "forgejo-state-dirs.service"
      ];
    };

    # services.gitea-actions-runner = {
    #   package = pkgs.forgejo-runner;
    #   instances.default = {
    #     enable = true;
    #     name = "monolith";
    #     url = "https://${domain}";

    #     # tokenFile must be an EnvironmentFile with TOKEN=<secret>
    #     tokenFile = config.age.secrets.forgejo-runner-token.path;

    #     labels = [
    #       "native:host"
    #     ];
    #   };
    # };

    systemd.services.forgejo.preStart = lib.mkAfter ''
      password="$(tr -d '\n' < ${config.age.secrets.forgejo-password.path})"

      ${lib.getExe cfg.package} admin user create \
        --admin \
        --email "${config.username}@localhost" \
        --username ${config.username} \
        --password "$password" \
        --must-change-password=false \
      || ${lib.getExe cfg.package} admin user change-password \
        --username ${config.username} \
        --password "$password" \
        --must-change-password=false
    '';
  };
}
