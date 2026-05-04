{...}: {
  moduleRegistry.nixos.immich = {
    config,
    lib,
    ...
  }: {
    users.groups.media = {};
    users.users.${config.username}.extraGroups = ["media"];
    users.users.${config.services.immich.user}.extraGroups = ["media"];

    services.immich = {
      enable = true;
      host = "0.0.0.0";
      port = 2283;
      openFirewall = true;
      mediaLocation = "/mnt/mergefs/photos";

      settings = {
        newVersionCheck.enabled = false;
      };
    };

    systemd.tmpfiles.rules = [
      "d /mnt/mergefs/programs/immich         2770 ${config.services.immich.user} media -"
    ];

    systemd.services = {
      immich-server = {
        after = ["mnt-mergefs.mount"];
        requires = ["mnt-mergefs.mount"];
      };
      immich-machine-learning = lib.mkIf config.services.immich.machine-learning.enable {
        after = ["mnt-mergefs.mount"];
        requires = ["mnt-mergefs.mount"];
      };
    };
  };
}
