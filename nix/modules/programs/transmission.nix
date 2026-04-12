{...}: {
  moduleRegistry.nixos.transmission = {
    config,
    lib,
    pkgs,
    ...
  }: {
    users.users.${config.username}.extraGroups = ["transmission"];

    systemd.services.transmission-state-dirs = {
      description = "Prepare Transmission state directories";
      before = ["transmission.service"];
      requiredBy = ["transmission.service"];
      after = ["mnt-mergefs.mount"];
      requires = ["mnt-mergefs.mount"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        ${pkgs.coreutils}/bin/install -d -m 0750 -o ${config.username} -g transmission \
          /mnt/mergefs/programs/transmission \
          /mnt/mergefs/programs/transmission/.config \
          /mnt/mergefs/programs/transmission/.config/transmission-daemon \
          /mnt/mergefs/programs/transmission/.incomplete \
          /mnt/mergefs/downloads
      '';
    };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      user = "reezpatel";

      home = "/mnt/mergefs/programs/transmission";

      openRPCPort = true;
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist = "127.0.0.1,192.168.2.0/24";
        download-dir = "/mnt/mergefs/downloads";
      };
    };

    systemd.services.transmission = {
      after = lib.mkAfter [
        "mnt-mergefs.mount"
        "transmission-state-dirs.service"
      ];
      requires = lib.mkAfter [
        "mnt-mergefs.mount"
        "transmission-state-dirs.service"
      ];
    };
  };
}
