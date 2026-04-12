{...}: {
  moduleRegistry.nixos.jellyfin = {config, ...}: {
    users.users.${config.username}.extraGroups = ["video" "render"];

    systemd.tmpfiles.rules = [
      "d /mnt/mergefs/programs/jellyfin/config 0700 ${config.username} users -"
      "d /mnt/mergefs/programs/jellyfin/cache  0700 ${config.username} users -"
      "d /mnt/mergefs/programs/jellyfin/log    0700 ${config.username} users -"
    ];

    systemd.services.jellyfin = {
      after = ["mnt-mergefs.mount"];
      requires = ["mnt-mergefs.mount"];
    };

    services.jellyfin = {
      enable = true;
      dataDir = "/mnt/mergefs/programs/jellyfin";
      cacheDir = "/mnt/mergefs/programs/jellyfin/cache";
      openFirewall = true;
      user = config.username;

      hardwareAcceleration = {
        enable = true;
        type = "nvenc";
        device = "/dev/nvidia0";
      };

      transcoding = {
        enableHardwareEncoding = true;
        hardwareDecodingCodecs = {
          h264 = true;
          hevc = true;
          hevc10bit = true;
          vp9 = true;
          av1 = true;
        };
        hardwareEncodingCodecs = {
          hevc = true;
          av1 = true;
        };
      };
    };
  };
}
