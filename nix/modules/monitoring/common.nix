{ lib, ... }:
{
  moduleRegistry.nixos.monitoringClient =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.monitoring.client;
    in
    {
      options.monitoring.client.lokiUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://192.168.2.2:3100/loki/api/v1/push";
        description = "Loki push URL for log shipping";
      };

      config = {
        services.prometheus.exporters.node = {
          enable = true;
          port = 9100;
          listenAddress = "0.0.0.0";
          enabledCollectors = [
            "cpu"
            "diskstats"
            "filesystem"
            "loadavg"
            "meminfo"
            "netdev"
            "netstat"
            "stat"
            "time"
            "uname"
            "vmstat"
            "systemd"
            "processes"
            "interrupts"
            "hwmon"
          ];
        };

        services.alloy = {
          enable = true;
          extraFlags = [ "--stability.level=generally-available" ];
          configPath = pkgs.writeText "alloy-config.alloy" ''
            loki.source.journal "journal" {
              forward_to    = [loki.write.trinity.receiver]
              relabel_rules = loki.relabel.journal.rules
              labels = {
                job  = "journal",
                host = "${config.networking.hostName}",
              }
            }

            loki.relabel "journal" {
              forward_to = []

              rule {
                source_labels = ["__journal__systemd_unit"]
                target_label  = "unit"
              }
              rule {
                source_labels = ["__journal__transport"]
                target_label  = "transport"
              }
              rule {
                source_labels = ["__journal_priority_keyword"]
                target_label  = "level"
              }
            }

            loki.write "trinity" {
              endpoint {
                url = "${cfg.lokiUrl}"
              }
            }
          '';
        };

        networking.firewall.allowedTCPPorts = [ 9100 ];
      };
    };
}
