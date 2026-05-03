{...}: {
  moduleRegistry.nixos.webdav = {
    pkgs,
    config,
    ...
  }: {
    age.secrets.webdav-password = {
      file = ../../../secerts/webdav-password.age;
      owner = config.username;
      mode = "0400";
    };

    systemd.services.webdav-htpasswd = {
      description = "Generate WebDAV htpasswd file";
      wantedBy = ["httpd.service"];
      before = ["httpd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.apacheHttpd}/bin/htpasswd -cbB /etc/httpd/webdav.htpasswd \
          ${config.username} "$(cat ${config.age.secrets.webdav-password.path})"
      '';
    };

    services.httpd = {
      enable = true;
      adminAddr = "admin@localhost";
      user = config.username;
      group = "users";

      virtualHosts.webdav = {
        listen = [{ip = "*"; port = 8097;}];
        documentRoot = "/mnt/mergefs";
        extraConfig = ''
          DAVLockDB /var/lib/httpd/DAVLock
          <Directory "/mnt/mergefs">
            DAV On
            Options Indexes
            AllowOverride None
            AuthType Basic
            AuthName "WebDAV"
            AuthUserFile /etc/httpd/webdav.htpasswd
            Require valid-user
          </Directory>
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d /mnt/mergefs 0755 ${config.username} users -"
      "d /var/lib/httpd 0750 ${config.username} users -"
    ];

    networking.firewall.allowedTCPPorts = [8097];
  };
}
