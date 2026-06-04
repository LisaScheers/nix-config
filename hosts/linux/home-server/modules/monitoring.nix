{
  lib,
  pkgs,
  ...
}: let
  grafanaDomain = "grafana.bylisa.dev";
  grafanaLocalDomain = "grafana.local.bylisa.dev";
  storageRoot = "/srv/disks/western-digital-hdd/monitoring";

  lokiAddress = "127.0.0.1";
  lokiPort = 3100;
  homeAssistantAddress = "127.0.0.1";
  homeAssistantPort = 8123;
  nginxExporterAddress = "127.0.0.1";
  nginxExporterPort = 9113;
  mimirAddress = "127.0.0.1";
  mimirPort = 9009;
  tempoAddress = "127.0.0.1";
  tempoPort = 3200;
  tempoOtlpGrpcPort = 14317;
  tempoOtlpHttpPort = 14318;
  pyroscopeAddress = "127.0.0.1";
  pyroscopePort = 4040;
  pyroscopeGrpcPort = 9098;
  pyroscopeMemberlistPort = 7947;
  alloyPyroscopePort = 4041;
  alloyAddress = "127.0.0.1";
  alloyPort = 12345;
  mimirUid = "mimir";
  lokiUid = "loki";
  tempoUid = "tempo";
  pyroscopeUid = "pyroscope";
  proxyErrorPage = import ./nginx-error-page.nix {inherit pkgs;};

  prometheusDatasource = {
    type = "prometheus";
    uid = mimirUid;
  };
  lokiDatasource = {
    type = "loki";
    uid = lokiUid;
  };

  prometheusTarget = refId: expr: legendFormat: {
    datasource = prometheusDatasource;
    inherit expr legendFormat refId;
  };

  lokiTarget = refId: expr: {
    datasource = lokiDatasource;
    inherit expr refId;
    queryType = "range";
  };

  statPanel = id: title: x: y: w: h: targets: unit: {
    inherit id title targets;
    type = "stat";
    datasource = prometheusDatasource;
    gridPos = {inherit x y w h;};
    options = {
      colorMode = "value";
      graphMode = "area";
      justifyMode = "auto";
      orientation = "auto";
      reduceOptions = {
        calcs = ["lastNotNull"];
        fields = "";
        values = false;
      };
      textMode = "auto";
    };
    fieldConfig.defaults = {
      color.mode = "thresholds";
      thresholds = {
        mode = "absolute";
        steps = [
          {
            color = "red";
            value = null;
          }
          {
            color = "green";
            value = 1;
          }
        ];
      };
      unit = unit;
    };
    fieldConfig.overrides = [];
  };

  timeseriesPanel = id: title: x: y: w: h: targets: unit: {
    inherit id title targets;
    type = "timeseries";
    datasource = prometheusDatasource;
    gridPos = {inherit x y w h;};
    fieldConfig.defaults = {
      custom = {
        drawStyle = "line";
        fillOpacity = 8;
        lineInterpolation = "linear";
        lineWidth = 1;
        pointSize = 5;
        showPoints = "never";
        spanNulls = false;
      };
      unit = unit;
    };
    fieldConfig.overrides = [];
    options = {
      legend = {
        calcs = ["lastNotNull"];
        displayMode = "table";
        placement = "bottom";
        showLegend = true;
      };
      tooltip = {
        mode = "multi";
        sort = "none";
      };
    };
  };

  logsPanel = id: title: x: y: w: h: expr: {
    inherit id title;
    type = "logs";
    datasource = lokiDatasource;
    gridPos = {inherit x y w h;};
    targets = [(lokiTarget "A" expr)];
    options = {
      dedupStrategy = "none";
      enableLogDetails = true;
      prettifyLogMessage = false;
      showCommonLabels = false;
      showLabels = false;
      showTime = true;
      sortOrder = "Descending";
    };
  };

  dashboard = uid: title: tags: panels: {
    inherit panels tags title uid;
    annotations.list = [];
    editable = false;
    fiscalYearStartMonth = 0;
    graphTooltip = 0;
    links = [];
    refresh = "30s";
    schemaVersion = 41;
    style = "dark";
    templating.list = [];
    time = {
      from = "now-6h";
      to = "now";
    };
    timepicker = {};
    timezone = "browser";
    version = 1;
  };

  dashboards = {
    "home-server-overview" = dashboard "home-server-overview" "Home Server Overview" ["home-server" "host"] [
      (statPanel 1 "Node up" 0 0 6 4 [(prometheusTarget "A" ''up{job="integrations/node_exporter"}'' "node")] "none")
      (statPanel 2 "Alloy up" 6 0 6 4 [(prometheusTarget "A" ''up{job="alloy"}'' "alloy")] "none")
      (statPanel 3 "Mimir up" 12 0 6 4 [(prometheusTarget "A" ''up{job="mimir"}'' "mimir")] "none")
      (statPanel 4 "Grafana up" 18 0 6 4 [(prometheusTarget "A" ''up{job="grafana"}'' "grafana")] "none")
      (timeseriesPanel 5 "CPU usage" 0 4 12 8 [(prometheusTarget "A" ''100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'' "CPU")] "percent")
      (timeseriesPanel 6 "Memory usage" 12 4 12 8 [(prometheusTarget "A" ''100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)'' "memory")] "percent")
      (timeseriesPanel 7 "Filesystem usage" 0 12 12 8 [(prometheusTarget "A" ''100 * (1 - node_filesystem_avail_bytes{mountpoint=~"/|/srv/disks/western-digital-hdd",fstype!~"tmpfs|devtmpfs|overlay"} / node_filesystem_size_bytes{mountpoint=~"/|/srv/disks/western-digital-hdd",fstype!~"tmpfs|devtmpfs|overlay"})'' "{{mountpoint}}")] "percent")
      (timeseriesPanel 8 "Load average" 12 12 12 8 [(prometheusTarget "A" ''node_load1'' "1m") (prometheusTarget "B" ''node_load5'' "5m") (prometheusTarget "C" ''node_load15'' "15m")] "none")
      (logsPanel 9 "System logs" 0 20 24 8 ''{unit=~"alloy.service|grafana.service|loki.service|mimir.service|nginx.service|podman-home-assistant.service|prometheus-nginx-exporter.service|pyroscope.service|tempo.service"}'')
    ];

    "observability-stack" = dashboard "observability-stack" "Observability Stack" ["grafana" "lgtm"] [
      (timeseriesPanel 1 "Stack target health" 0 0 24 8 [(prometheusTarget "A" ''up{job=~"grafana|loki|mimir|tempo|pyroscope|alloy"}'' "{{job}}")] "none")
      (timeseriesPanel 2 "Alloy remote write rate" 0 8 12 8 [(prometheusTarget "A" ''sum(rate(prometheus_remote_storage_samples_total[5m]))'' "samples/s")] "ops")
      (timeseriesPanel 3 "Alloy pending samples" 12 8 12 8 [(prometheusTarget "A" ''sum(prometheus_remote_storage_samples_pending)'' "pending")] "short")
      (timeseriesPanel 4 "Loki ingest requests" 0 16 12 8 [(prometheusTarget "A" ''sum(rate(loki_request_duration_seconds_count[5m])) by (route)'' "{{route}}")] "rps")
      (timeseriesPanel 5 "Mimir request rate" 12 16 12 8 [(prometheusTarget "A" ''sum(rate(cortex_request_duration_seconds_count[5m])) by (route)'' "{{route}}")] "rps")
      (logsPanel 6 "Observability service logs" 0 24 24 8 ''{unit=~"alloy.service|grafana.service|loki.service|mimir.service|pyroscope.service|tempo.service"}'')
    ];

    "nginx" = dashboard "nginx" "Nginx" ["nginx" "proxy"] [
      (statPanel 1 "Nginx up" 0 0 6 4 [(prometheusTarget "A" ''nginx_up'' "nginx")] "none")
      (timeseriesPanel 2 "Requests" 6 0 18 8 [(prometheusTarget "A" ''rate(nginx_http_requests_total[5m])'' "requests/s")] "rps")
      (timeseriesPanel 3 "Connections" 0 8 12 8 [(prometheusTarget "A" ''nginx_connections_active'' "active") (prometheusTarget "B" ''nginx_connections_reading'' "reading") (prometheusTarget "C" ''nginx_connections_writing'' "writing") (prometheusTarget "D" ''nginx_connections_waiting'' "waiting")] "short")
      (timeseriesPanel 4 "Accepted and handled connections" 12 8 12 8 [(prometheusTarget "A" ''rate(nginx_connections_accepted[5m])'' "accepted/s") (prometheusTarget "B" ''rate(nginx_connections_handled[5m])'' "handled/s")] "cps")
      (logsPanel 5 "Nginx logs" 0 16 24 8 ''{unit="nginx.service"}'')
    ];

    "home-assistant" = dashboard "home-assistant" "Home Assistant" ["home-assistant" "iot"] [
      (statPanel 1 "Home Assistant up" 0 0 6 4 [(prometheusTarget "A" ''up{job="home-assistant"}'' "home-assistant")] "none")
      (timeseriesPanel 2 "Process memory" 6 0 9 8 [(prometheusTarget "A" ''process_resident_memory_bytes{job="home-assistant"}'' "RSS")] "bytes")
      (timeseriesPanel 3 "Process CPU" 15 0 9 8 [(prometheusTarget "A" ''rate(process_cpu_seconds_total{job="home-assistant"}[5m])'' "CPU seconds/s")] "cores")
      (timeseriesPanel 4 "Python GC collections" 0 8 12 8 [(prometheusTarget "A" ''sum by (generation) (rate(python_gc_collections_total{job="home-assistant"}[5m]))'' "gen {{generation}}")] "ops")
      (timeseriesPanel 5 "Scrape health" 12 8 12 8 [(prometheusTarget "A" ''scrape_duration_seconds{job="home-assistant"}'' "duration") (prometheusTarget "B" ''scrape_samples_scraped{job="home-assistant"}'' "samples")] "short")
      (logsPanel 6 "Home Assistant logs" 0 16 24 8 ''{unit="podman-home-assistant.service"}'')
    ];
  };

  dashboardPath = pkgs.linkFarm "grafana-dashboards" (
    lib.mapAttrsToList (name: dashboardJson: {
      name = "${name}.json";
      path = pkgs.writeText "${name}.json" (builtins.toJSON dashboardJson);
    })
    dashboards
  );

  alloyConfig = pkgs.writeText "config.alloy" ''
    prometheus.remote_write "mimir" {
      endpoint {
        url = "http://${mimirAddress}:${toString mimirPort}/api/v1/push"
      }
    }

    prometheus.exporter.unix "home_server" {
      enable_collectors = ["systemd"]
    }

    discovery.relabel "home_server" {
      targets = prometheus.exporter.unix.home_server.targets

      rule {
        target_label = "instance"
        replacement  = constants.hostname
      }

      rule {
        target_label = "job"
        replacement  = "integrations/node_exporter"
      }
    }

    prometheus.scrape "home_server" {
      targets         = discovery.relabel.home_server.output
      forward_to      = [prometheus.remote_write.mimir.receiver]
      scrape_interval = "15s"
    }

    prometheus.scrape "grafana_stack" {
      targets = [
        {"__address__" = "127.0.0.1:3000",  "job" = "grafana", "instance" = constants.hostname},
        {"__address__" = "${lokiAddress}:${toString lokiPort}",  "job" = "loki",    "instance" = constants.hostname},
        {"__address__" = "${mimirAddress}:${toString mimirPort}", "job" = "mimir",   "instance" = constants.hostname},
        {"__address__" = "${tempoAddress}:${toString tempoPort}", "job" = "tempo",   "instance" = constants.hostname},
        {"__address__" = "${pyroscopeAddress}:${toString pyroscopePort}", "job" = "pyroscope", "instance" = constants.hostname},
        {"__address__" = "${alloyAddress}:${toString alloyPort}", "job" = "alloy",   "instance" = constants.hostname},
      ]
      forward_to      = [prometheus.remote_write.mimir.receiver]
      scrape_interval = "15s"
    }

    prometheus.scrape "home_assistant" {
      targets = [
        {"__address__" = "${homeAssistantAddress}:${toString homeAssistantPort}", "job" = "home-assistant", "instance" = constants.hostname},
      ]
      forward_to      = [prometheus.remote_write.mimir.receiver]
      metrics_path    = "/api/prometheus"
      scrape_interval = "60s"
    }

    prometheus.scrape "nginx" {
      targets = [
        {"__address__" = "${nginxExporterAddress}:${toString nginxExporterPort}", "job" = "nginx", "instance" = constants.hostname},
      ]
      forward_to      = [prometheus.remote_write.mimir.receiver]
      scrape_interval = "15s"
    }

    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal__boot_id"]
        target_label  = "boot_id"
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

    loki.write "local" {
      endpoint {
        url = "http://${lokiAddress}:${toString lokiPort}/loki/api/v1/push"
      }
    }

    loki.source.journal "system" {
      max_age       = "24h"
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.local.receiver]
    }

    otelcol.receiver.otlp "local" {
      grpc {
        endpoint = "127.0.0.1:4317"
      }

      http {
        endpoint = "127.0.0.1:4318"
      }

      output {
        metrics = [otelcol.processor.batch.local.input]
        logs    = [otelcol.processor.batch.local.input]
        traces  = [otelcol.processor.batch.local.input]
      }
    }

    otelcol.processor.batch "local" {
      output {
        metrics = [otelcol.exporter.prometheus.otlp_metrics.input]
        logs    = [otelcol.exporter.loki.otlp_logs.input]
        traces  = [otelcol.exporter.otlp.tempo.input]
      }
    }

    otelcol.exporter.prometheus "otlp_metrics" {
      forward_to = [prometheus.remote_write.mimir.receiver]
    }

    otelcol.exporter.loki "otlp_logs" {
      forward_to = [loki.write.local.receiver]
    }

    otelcol.exporter.otlp "tempo" {
      client {
        endpoint = "${tempoAddress}:${toString tempoOtlpGrpcPort}"

        tls {
          insecure = true
        }
      }
    }

    pyroscope.write "local" {
      endpoint {
        url = "http://${pyroscopeAddress}:${toString pyroscopePort}"
      }
    }

    pyroscope.receive_http "local" {
      http {
        listen_address = "127.0.0.1"
        listen_port    = ${toString alloyPyroscopePort}
      }

      forward_to = [pyroscope.write.local.receiver]
    }
  '';
in {
  environment.etc."alloy/config.alloy".source = alloyConfig;

  systemd.tmpfiles.rules = [
    "d ${storageRoot} 0755 root root -"
    "d ${storageRoot}/grafana 0750 grafana grafana -"
    "d ${storageRoot}/loki 0750 loki loki -"
    "d ${storageRoot}/mimir 0750 mimir mimir -"
    "d ${storageRoot}/tempo 0750 tempo tempo -"
    "d ${storageRoot}/pyroscope 0750 pyroscope pyroscope -"
  ];

  users = {
    groups = {
      mimir = {};
      pyroscope = {};
      tempo = {};
    };
    users = {
      mimir = {
        description = "Mimir service user";
        group = "mimir";
        home = "${storageRoot}/mimir";
        isSystemUser = true;
      };
      pyroscope = {
        description = "Pyroscope service user";
        group = "pyroscope";
        home = "${storageRoot}/pyroscope";
        isSystemUser = true;
      };
      tempo = {
        description = "Tempo service user";
        group = "tempo";
        home = "${storageRoot}/tempo";
        isSystemUser = true;
      };
    };
  };

  services.grafana = {
    enable = true;
    dataDir = "${storageRoot}/grafana";
    settings = {
      analytics.reporting_enabled = false;
      log.mode = "console";
      metrics.enabled = true;
      security = {
        admin_user = "admin";
        secret_key = "$__file{${storageRoot}/grafana/secret_key}";
      };
      server = {
        domain = grafanaDomain;
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://${grafanaDomain}/";
      };
    };
    provision = {
      enable = true;
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "home-server";
            type = "file";
            disableDeletion = false;
            editable = false;
            updateIntervalSeconds = 30;
            options = {
              path = dashboardPath;
              foldersFromFilesStructure = false;
            };
          }
        ];
      };
      datasources.settings = {
        apiVersion = 1;
        prune = true;
        deleteDatasources = [
          {
            name = "Loki";
            orgId = 1;
          }
          {
            name = "Mimir";
            orgId = 1;
          }
          {
            name = "Tempo";
            orgId = 1;
          }
          {
            name = "Pyroscope";
            orgId = 1;
          }
        ];
        datasources = [
          {
            name = "Loki";
            uid = lokiUid;
            type = "loki";
            access = "proxy";
            url = "http://${lokiAddress}:${toString lokiPort}";
            jsonData.maxLines = 1000;
          }
          {
            name = "Mimir";
            uid = mimirUid;
            type = "prometheus";
            access = "proxy";
            url = "http://${mimirAddress}:${toString mimirPort}/prometheus";
            isDefault = true;
            jsonData = {
              httpMethod = "POST";
            };
          }
          {
            name = "Pyroscope";
            uid = pyroscopeUid;
            type = "grafana-pyroscope-datasource";
            access = "proxy";
            url = "http://${pyroscopeAddress}:${toString pyroscopePort}";
            jsonData.minStep = "15s";
          }
          {
            name = "Tempo";
            uid = tempoUid;
            type = "tempo";
            access = "proxy";
            url = "http://${tempoAddress}:${toString tempoPort}";
            jsonData = {
              nodeGraph.enabled = true;
              serviceMap.datasourceUid = mimirUid;
              tracesToLogsV2 = {
                datasourceUid = lokiUid;
                filterByTraceID = true;
                filterBySpanID = false;
                spanStartTimeShift = "-5m";
                spanEndTimeShift = "5m";
                tags = [
                  {
                    key = "service.name";
                    value = "service";
                  }
                  {
                    key = "host.name";
                    value = "instance";
                  }
                ];
              };
              tracesToMetrics = {
                datasourceUid = mimirUid;
                spanStartTimeShift = "-5m";
                spanEndTimeShift = "5m";
                tags = [
                  {
                    key = "service.name";
                    value = "service";
                  }
                  {
                    key = "host.name";
                    value = "instance";
                  }
                ];
                queries = [
                  {
                    name = "Request rate";
                    query = "sum(rate(traces_spanmetrics_calls_total{$${__tags}}[5m]))";
                  }
                  {
                    name = "Latency p95";
                    query = "histogram_quantile(0.95, sum(rate(traces_spanmetrics_latency_bucket{$${__tags}}[5m])) by (le))";
                  }
                ];
              };
              tracesToProfiles = {
                datasourceUid = pyroscopeUid;
                profileTypeId = "process_cpu:cpu:nanoseconds:cpu:nanoseconds";
                tags = [
                  {
                    key = "service.name";
                    value = "service_name";
                  }
                ];
              };
            };
          }
        ];
      };
    };
  };

  services.loki = {
    enable = true;
    dataDir = "${storageRoot}/loki";
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = lokiAddress;
        http_listen_port = lokiPort;
        grpc_listen_address = lokiAddress;
        grpc_listen_port = 9096;
      };
      common = {
        instance_addr = lokiAddress;
        path_prefix = "${storageRoot}/loki";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "${storageRoot}/loki/chunks";
          rules_directory = "${storageRoot}/loki/rules";
        };
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
      compactor = {
        working_directory = "${storageRoot}/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
      limits_config = {
        retention_period = "30d";
        allow_structured_metadata = true;
      };
    };
  };

  services.mimir = {
    enable = true;
    extraFlags = ["-target=all"];
    configuration = {
      multitenancy_enabled = false;
      server = {
        http_listen_address = mimirAddress;
        http_listen_port = mimirPort;
        grpc_listen_address = "0.0.0.0";
        grpc_listen_port = 9095;
        log_level = "warn";
      };
      blocks_storage = {
        backend = "filesystem";
        bucket_store.sync_dir = "${storageRoot}/mimir/tsdb-sync";
        filesystem.dir = "${storageRoot}/mimir/data/tsdb";
        tsdb.dir = "${storageRoot}/mimir/tsdb";
      };
      compactor = {
        data_dir = "${storageRoot}/mimir/compactor";
        sharding_ring.kvstore.store = "memberlist";
      };
      distributor.ring = {
        instance_addr = mimirAddress;
        kvstore.store = "memberlist";
      };
      ingester.ring = {
        instance_addr = mimirAddress;
        kvstore.store = "memberlist";
        replication_factor = 1;
      };
      memberlist = {
        bind_addr = [mimirAddress];
        bind_port = 7946;
        advertise_addr = mimirAddress;
        advertise_port = 7946;
      };
      ruler_storage = {
        backend = "filesystem";
        filesystem.dir = "${storageRoot}/mimir/rules";
      };
      store_gateway.sharding_ring.replication_factor = 1;
      usage_stats.enabled = false;
    };
  };

  services.tempo = {
    enable = true;
    extraFlags = ["-target=all"];
    settings = {
      auth_enabled = false;
      server = {
        http_listen_address = tempoAddress;
        http_listen_port = tempoPort;
        grpc_listen_address = tempoAddress;
        grpc_listen_port = 9097;
      };
      distributor.receivers.otlp.protocols = {
        grpc.endpoint = "${tempoAddress}:${toString tempoOtlpGrpcPort}";
        http.endpoint = "${tempoAddress}:${toString tempoOtlpHttpPort}";
      };
      storage.trace = {
        backend = "local";
        local.path = "${storageRoot}/tempo/traces";
        wal.path = "${storageRoot}/tempo/wal";
      };
      compactor.compaction.block_retention = "336h";
    };
  };

  services.pyroscope = {
    enable = true;
    extraFlags = ["-target=all"];
    settings = {
      analytics.reporting_enabled = false;
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = pyroscopePort;
        grpc_listen_address = "0.0.0.0";
        grpc_listen_port = pyroscopeGrpcPort;
      };
      memberlist = {
        bind_addr = [pyroscopeAddress];
        bind_port = pyroscopeMemberlistPort;
        advertise_addr = pyroscopeAddress;
        advertise_port = pyroscopeMemberlistPort;
      };
      storage = {
        backend = "filesystem";
        filesystem.dir = "${storageRoot}/pyroscope/data";
      };
    };
  };

  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=${alloyAddress}:${toString alloyPort}"
      "--disable-reporting"
    ];
  };

  services.nginx.statusPage = true;

  services.prometheus.exporters.nginx = {
    enable = true;
    listenAddress = nginxExporterAddress;
    port = nginxExporterPort;
    scrapeUri = "http://127.0.0.1/nginx_status";
  };

  services.nginx.virtualHosts.${grafanaDomain} = lib.mkMerge [
    proxyErrorPage
    {
      serverAliases = [grafanaLocalDomain];
      forceSSL = true;
      useACMEHost = grafanaDomain;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    }
  ];

  systemd.services = {
    alloy = {
      after = [
        "loki.service"
        "mimir.service"
        "pyroscope.service"
        "tempo.service"
      ];
      wants = [
        "loki.service"
        "mimir.service"
        "pyroscope.service"
        "tempo.service"
      ];
      unitConfig.RequiresMountsFor = storageRoot;
    };

    grafana = {
      after = [
        "loki.service"
        "mimir.service"
        "pyroscope.service"
        "tempo.service"
      ];
      wants = [
        "loki.service"
        "mimir.service"
        "pyroscope.service"
        "tempo.service"
      ];
      unitConfig.RequiresMountsFor = storageRoot;
      preStart = lib.mkBefore ''
        if [ ! -s ${storageRoot}/grafana/secret_key ]; then
          umask 077
          ${pkgs.openssl}/bin/openssl rand -base64 32 > ${storageRoot}/grafana/secret_key
        fi
      '';
    };

    loki.unitConfig.RequiresMountsFor = storageRoot;
    mimir = {
      unitConfig.RequiresMountsFor = storageRoot;
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "mimir";
        Group = "mimir";
        WorkingDirectory = lib.mkForce "${storageRoot}/mimir";
      };
    };
    pyroscope = {
      unitConfig.RequiresMountsFor = storageRoot;
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "pyroscope";
        Group = "pyroscope";
        WorkingDirectory = lib.mkForce "${storageRoot}/pyroscope";
      };
    };
    tempo = {
      unitConfig.RequiresMountsFor = storageRoot;
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "tempo";
        Group = "tempo";
        WorkingDirectory = lib.mkForce "${storageRoot}/tempo";
      };
    };
  };
}
