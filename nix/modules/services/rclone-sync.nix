{ ... }: {
  flake.modules.nixos.rclone-sync =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.rcloneSync;
      remoteConfig = lib.concatMapStringsSep "\n" (target: ''
        [${target.name}]
        type = sftp
        host = ${target.host}
        user = ${target.user}
        port = ${toString target.port}
        key_file = ${cfg.sshKeyFile}
        shell_type = unix
        md5sum_command = none
        sha1sum_command = none
      '') cfg.targets;

      syncScripts = lib.listToAttrs (
        map (target: {
          name = "rclone-sync-${target.name}";
          value = pkgs.writeShellScript "rclone-sync-${target.name}" ''
            set -euo pipefail

            snapshot_dir="${target.path}/.rclone-snapshots/${config.hostname}/$(date -u +%Y%m%dT%H%M%SZ)"

            ${lib.getExe pkgs.rclone} sync \
              ${lib.escapeShellArg cfg.source} \
              ${lib.escapeShellArg "${target.name}:${target.path}"} \
              --config ${lib.escapeShellArg cfg.configFile} \
              --backup-dir ${lib.escapeShellArg "${target.name}:"}"$snapshot_dir"} \
              --create-empty-src-dirs \
              --links \
              --fast-list \
              --exclude ${lib.escapeShellArg "/.rclone-snapshots/**"} \
              --checkers ${toString cfg.checkers} \
              --transfers ${toString cfg.transfers} \
              --stats 1m \
              --log-level INFO

            ${lib.getExe pkgs.rclone} delete \
              ${lib.escapeShellArg "${target.name}:${target.path}/.rclone-snapshots/${config.hostname}"} \
              --config ${lib.escapeShellArg cfg.configFile} \
              --min-age ${lib.escapeShellArg cfg.snapshotRetention} \
              --rmdirs \
              --log-level INFO
          '';
        }) cfg.targets
      );
    in
    {
      options.services.rcloneSync = {
        enable = lib.mkEnableOption "scheduled rclone sync jobs";

        source = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/mergefs";
          description = "Local source directory to sync.";
        };

        interval = lib.mkOption {
          type = lib.types.str;
          default = "*-*-* 00/6:00:00";
          description = "Systemd OnCalendar interval for sync jobs.";
        };

        sshKeyFile = lib.mkOption {
          type = lib.types.str;
          default = "/root/.ssh/id_ed25519";
          description = "SSH private key used by rclone SFTP remotes.";
        };

        configFile = lib.mkOption {
          type = lib.types.path;
          readOnly = true;
          default = pkgs.writeText "rclone-sync.conf" remoteConfig;
          description = "Generated rclone config file.";
        };

        checkers = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8;
          description = "Number of rclone checkers.";
        };

        transfers = lib.mkOption {
          type = lib.types.ints.positive;
          default = 4;
          description = "Number of concurrent rclone transfers.";
        };

        snapshotRetention = lib.mkOption {
          type = lib.types.str;
          default = "30d";
          description = "How long to retain destination snapshots of overwritten/deleted files.";
        };

        targets = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Rclone remote name.";
                };
                host = lib.mkOption {
                  type = lib.types.str;
                  description = "SSH host for the destination.";
                };
                user = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                  description = "SSH user for the destination.";
                };
                port = lib.mkOption {
                  type = lib.types.port;
                  # All hosts run sshd on 7272 (see features/linux/system.nix).
                  default = 7272;
                  description = "SSH port for the destination.";
                };
                path = lib.mkOption {
                  type = lib.types.str;
                  default = "/mnt/mergefs";
                  description = "Destination path.";
                };
              };
            }
          );
          default = [ ];
          description = "Rclone SFTP sync targets.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.targets != [ ];
            message = "services.rcloneSync.targets must contain at least one target.";
          }
        ];

        environment.systemPackages = with pkgs; [
          openssh
          rclone
        ];

        systemd.services = lib.mapAttrs' (
          name: script:
          lib.nameValuePair name {
            description = "Rclone sync ${cfg.source} to ${name}";
            after = [
              "network-online.target"
              "mnt-mergefs.mount"
            ];
            wants = [ "network-online.target" ];
            requires = [ "mnt-mergefs.mount" ];
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = script;
              Nice = 10;
              IOSchedulingClass = "best-effort";
              IOSchedulingPriority = 7;
            };
          }
        ) syncScripts;

        systemd.timers = lib.mapAttrs' (
          name: _:
          let
            serviceName = "${name}.service";
          in
          lib.nameValuePair name {
            description = "Schedule ${serviceName}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = cfg.interval;
              Persistent = true;
              RandomizedDelaySec = "30m";
              Unit = serviceName;
            };
          }
        ) syncScripts;
      };
    };
}
