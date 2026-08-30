{...}: {
  flake.modules.nixos.waha = {
    config,
    lib,
    pkgs,
    ...
  }: let
    wahaImage = "docker.io/devlikeapro/waha:latest";
    wahaDir = "/mnt/mergefs/containers/waha";
  in {
    networking.firewall.allowedTCPPorts = [8834];

    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    systemd.services.waha-state-dirs = {
      description = "Prepare WAHA container directories";
      after = ["mnt-mergefs.mount"];
      requires = ["mnt-mergefs.mount"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        ${pkgs.coreutils}/bin/install -d -m 0750 -o ${config.username} -g users \
          ${lib.escapeShellArg wahaDir} \
          ${lib.escapeShellArg "${wahaDir}/sessions"}
      '';
    };

    systemd.services.waha = {
      description = "WAHA WhatsApp HTTP API";
      after = [
        "network-online.target"
        "podman.socket"
        "waha-state-dirs.service"
      ];
      requires = [
        "podman.socket"
        "waha-state-dirs.service"
      ];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStartPre = "-${lib.getExe pkgs.podman} rm -f waha";
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.podman)
          "run"
          "--rm"
          "--pull=missing"
          "--env-file"
          (lib.escapeShellArg "${wahaDir}/.env")
          "-v"
          (lib.escapeShellArg "${wahaDir}/sessions:/app/.sessions")
          "-p"
          "8834:3000"
          "--name"
          "waha"
          (lib.escapeShellArg wahaImage)
        ];
        ExecStop = "${lib.getExe pkgs.podman} stop waha";
        Restart = "always";
        RestartSec = "10s";
        TimeoutStopSec = "70s";
      };
    };
  };
}
