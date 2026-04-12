{...}: {
  moduleRegistry.nixos.samba = {
    config,
    pkgs,
    ...
  }: {
    age.secrets.samba-password.file = ../../../secerts/samba-password.age;

    systemd.services.samba-set-password = {
      description = "Set Samba password for ${config.username}";
      wantedBy = ["multi-user.target"];
      after = ["samba-smbd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeShellScript "samba-set-password" ''
          password=$(cat ${config.age.secrets.samba-password.path})
          printf '%s\n%s\n' "$password" "$password" | ${pkgs.samba}/bin/pdbedit -a -u ${config.username} -t
        '';
      };
    };

    # WS-Discovery — needed for modern macOS/Windows network browsing
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    services.samba = {
      enable = true;
      openFirewall = true;

      settings = {
        global = {
          # macOS compatibility
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:veto_appledouble" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "vfs objects" = "catia fruit streams_xattr";

          # Performance tuning
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
          "read raw" = "yes";
          "write raw" = "yes";
          "max xmit" = "65535";
          "dead time" = "15";
          "use sendfile" = "yes";
          "aio read size" = "16384";
          "aio write size" = "16384";

          # Security
          "server min protocol" = "SMB2";
          "ntlm auth" = "no";
          "restrict anonymous" = "2";

          workgroup = "WORKGROUP";
          "server string" = config.hostname;
        };

        mergefs = {
          path = "/mnt/mergefs";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = config.username;
          "force user" = config.username;
          "force group" = "media";
          "create mask" = "0664";
          "directory mask" = "0775";
          "force create mode" = "0664";
          "force directory mode" = "0775";
          "delete readonly" = "yes";

          # macOS extended attributes & spotlight
          "fruit:aapl" = "yes";
          "fruit:time machine" = "no";
          "spotlight" = "yes";
        };
      };
    };
  };
}
