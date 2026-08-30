{ ... }: {
  flake.modules.nixos.monitoring-server =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      lokiDataDir = "/var/lib/loki";
      grafanaDataDir = "/var/lib/grafana";
      prometheusStateDir = "prometheus2";

      # All hosts are scraped over the NetBird mesh: node-exporter (9100) is
      # mesh-only fleet-wide (monitoring.client.publicFirewall defaults false).
      nodeTargets =
        map (host: "${host}.netbird.selfhosted:9100") [
          "trinity"
          "vixen"
          "divine"
          "muse"
          "rpi1"
          "rpi2"
          "rpi3"
          "rpi4"
          "rpi5"
          "slayer"
        ];

      instanceRelabel = [
        {
          source_labels = [ "__address__" ];
          regex = "([^:]+):.*";
          target_label = "instance";
          replacement = "\${1}";
        }
      ];
    in
    {
      services.prometheus = {
        enable = true;
        port = 9090;
        listenAddress = "0.0.0.0";
        stateDir = prometheusStateDir;
        retentionTime = "90d";
        checkConfig = "syntax-only";

        globalConfig = {
          scrape_interval = "30s";
          evaluation_interval = "30s";
        };

        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [ { targets = nodeTargets; } ];
            relabel_configs = instanceRelabel;
          }
          {
            # forgejo built-in /metrics endpoint (port 9965, path /metrics)
            job_name = "forgejo";
            metrics_path = "/metrics";
            static_configs = [ { targets = [ "vixen:9965" ]; } ];
            relabel_configs = instanceRelabel;
          }
          {
            # immich server metrics (port 8081)
            job_name = "immich";
            static_configs = [
              {
                targets = [
                  "vixen:8081"
                  "vixen:8082"
                ];
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                regex = "vixen:8081";
                target_label = "service";
                replacement = "immich-server";
              }
              {
                source_labels = [ "__address__" ];
                regex = "vixen:8082";
                target_label = "service";
                replacement = "immich-microservices";
              }
            ]
            ++ instanceRelabel;
          }
          {
            job_name = "postgres";
            static_configs = [
              {
                targets = [
                  "vixen:9187"
                  "slayer:9187"
                ];
              }
            ];
            relabel_configs = instanceRelabel;
          }
          {
            # netbird management metrics (slayer, via the mesh).
            # NOTE: management binds metrics on 127.0.0.1:9090 by default -
            # this job will fail until that is deliberately exposed.
            job_name = "netbird";
            static_configs = [ { targets = [ "slayer.netbird.selfhosted:9090" ]; } ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "instance";
                replacement = "slayer";
              }
            ];
          }
          {
            job_name = "home-assistant";
            metrics_path = "/api/prometheus";
            authorization.credentials_file = config.age.secrets.home-assistant-token.path;
            static_configs = [ { targets = [ "rpi1:8123" ]; } ];
            relabel_configs = instanceRelabel;
          }
          {
            job_name = "jellyfin";
            static_configs = [ { targets = [ "vixen:9594" ]; } ];
            relabel_configs = instanceRelabel;
          }
        ];
      };

      services.loki = {
        enable = true;
        dataDir = lokiDataDir;

        configuration = {
          auth_enabled = false;

          server = {
            http_listen_port = 3100;
            grpc_listen_port = 9096;
            http_listen_address = "0.0.0.0";
          };

          common = {
            instance_addr = "127.0.0.1";
            path_prefix = lokiDataDir;
            replication_factor = 1;
            ring.kvstore.store = "inmemory";
            storage.filesystem = {
              chunks_directory = "${lokiDataDir}/chunks";
              rules_directory = "${lokiDataDir}/rules";
            };
          };

          query_range.results_cache.cache.embedded_cache = {
            enabled = true;
            max_size_mb = 100;
          };

          limits_config = {
            retention_period = "2160h";
            ingestion_rate_mb = 16;
            ingestion_burst_size_mb = 32;
            max_query_series = 10000;
          };

          compactor = {
            working_directory = "${lokiDataDir}/retention";
            retention_enabled = true;
            delete_request_store = "filesystem";
          };

          schema_config.configs = [
            {
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];

          ruler.alertmanager_url = "http://localhost:9093";
        };
      };

      age.secrets.home-assistant-token = {
        file = ../../../secerts/home-assistant-token.age;
        owner = "prometheus";
        group = "prometheus";
        mode = "0400";
      };

      age.secrets.grafana-secret-key = {
        file = ../../../secerts/grafana-secret-key.age;
        owner = "grafana";
        group = "grafana";
        mode = "0400";
      };

      age.secrets.grafana-admin-password = {
        file = ../../../secerts/grafana-admin-password.age;
        owner = "grafana";
        group = "grafana";
        mode = "0400";
      };

      services.grafana = {
        enable = true;
        dataDir = grafanaDataDir;

        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
            domain = "trinity";
          };

          security = {
            admin_user = "reezpatel";
            admin_password = "$__file{${config.age.secrets.grafana-admin-password.path}}";
            secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
          };

          analytics.reporting_enabled = false;
        };

        provision = {
          enable = true;

          datasources.settings = {
            apiVersion = 1;
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                url = "http://localhost:9090";
                isDefault = true;
                editable = false;
              }
              {
                name = "Loki";
                type = "loki";
                url = "http://localhost:3100";
                isDefault = false;
                editable = false;
              }
            ];
          };
        };
      };

      networking.firewall.allowedTCPPorts = [
        3000
        3100
        9090
        9100
      ];
    };
}
