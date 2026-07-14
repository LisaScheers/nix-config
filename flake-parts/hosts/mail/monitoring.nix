{
  config,
  pkgs,
  ...
}: let
  instance = "mail";
  otlpEndpoint = "https://grafana.bylisa.dev/otlp";
  alloyAddress = "127.0.0.1";
  alloyPort = 12345;
  nginxExporterPort = 9113;
  postfixExporterPort = 9154;

  alloyConfig = pkgs.writeText "mail-alloy-config.alloy" ''
    otelcol.auth.basic "home_server" {
      username = sys.env("OTLP_USERNAME")
      password = sys.env("OTLP_PASSWORD")
    }

    otelcol.exporter.otlphttp "home_server" {
      client {
        endpoint = "${otlpEndpoint}"
        auth     = otelcol.auth.basic.home_server.handler
      }
    }

    otelcol.processor.batch "home_server" {
      output {
        metrics = [otelcol.exporter.otlphttp.home_server.input]
        logs    = [otelcol.exporter.otlphttp.home_server.input]
        traces  = [otelcol.exporter.otlphttp.home_server.input]
      }
    }

    otelcol.receiver.prometheus "local" {
      output {
        metrics = [otelcol.processor.batch.home_server.input]
      }
    }

    prometheus.exporter.unix "host" {
      enable_collectors = ["systemd"]
    }

    discovery.relabel "host" {
      targets = prometheus.exporter.unix.host.targets

      rule {
        target_label = "instance"
        replacement  = "${instance}"
      }

      rule {
        target_label = "job"
        # Preserve the historical label used by the existing Grafana dashboards.
        replacement  = "mailcow-node"
      }
    }

    prometheus.scrape "host" {
      targets         = discovery.relabel.host.output
      forward_to      = [otelcol.receiver.prometheus.local.receiver]
      scrape_interval = "15s"
    }

    prometheus.scrape "mail_services" {
      targets = [
        {"__address__" = "${alloyAddress}:${toString alloyPort}", "job" = "mail-alloy", "instance" = "${instance}"},
        {"__address__" = "127.0.0.1:${toString nginxExporterPort}", "job" = "mail-nginx", "instance" = "${instance}"},
        {"__address__" = "127.0.0.1:${toString postfixExporterPort}", "job" = "mail-postfix", "instance" = "${instance}"},
      ]
      forward_to      = [otelcol.receiver.prometheus.local.receiver]
      scrape_interval = "15s"
    }

    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
    }

    otelcol.receiver.loki "journal" {
      output {
        logs = [otelcol.processor.batch.home_server.input]
      }
    }

    loki.source.journal "system" {
      max_age       = "24h"
      labels        = {"instance" = "${instance}", "source" = "journal"}
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [otelcol.receiver.loki.journal.receiver]
    }
  '';
in {
  age.secrets.monitoring-otlp-env = {
    file = ../../agenix/secrets/mail/monitoring-otlp-env.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  environment.etc."alloy/config.alloy".source = alloyConfig;

  services.alloy = {
    enable = true;
    environmentFile = config.age.secrets.monitoring-otlp-env.path;
    extraFlags = [
      "--server.http.listen-addr=${alloyAddress}:${toString alloyPort}"
      "--disable-reporting"
    ];
  };

  services.prometheus.exporters = {
    nginx = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = nginxExporterPort;
      scrapeUri = "http://127.0.0.1/nginx_status";
    };
    postfix = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = postfixExporterPort;
    };
  };

  systemd.services.alloy = {
    after = [
      "prometheus-nginx-exporter.service"
      "prometheus-postfix-exporter.service"
    ];
    restartTriggers = [../../agenix/secrets/mail/monitoring-otlp-env.age];
  };
}
