{...}: {
  localModules.nixos."home-server-home-assistant" = {
    lib,
    pkgs,
    ...
  }: let
    primaryDomain = "ha.bylisa.dev";
    localDomain = "ha.local.bylisa.dev";
    proxyErrorPage = import ./_nginx-error-page.nix {inherit pkgs;};
    configurationFile =
      (pkgs.formats.yaml {}).generate "configuration.yaml"
      {
        homeassistant = {
          name = "Home Assistant";
          #51.203108, 4.769569
          latitude = "51.203108";
          longitude = "4.769569";
          unit_system = "metric";
          time_zone = "Europe/Brussels";
          temperature_unit = "C";
          external_url = "https://${primaryDomain}";
          internal_url = "https://${localDomain}";
        };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
        };
        prometheus = {
          namespace = "homeassistant";
          requires_auth = false;
        };
      };
  in {
    environment.etc."home-assistant/configuration.yaml".source = configurationFile;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    hardware.enableRedistributableFirmware = true;

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts.${primaryDomain} = lib.mkMerge [
        proxyErrorPage
        {
          serverAliases = [localDomain];
          forceSSL = true;
          useACMEHost = primaryDomain;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8123";
            proxyWebsockets = true;
          };
        }
      ];
    };

    virtualisation = {
      podman.enable = true;
      oci-containers = {
        backend = "podman";
        containers.home-assistant = {
          image = "ghcr.io/home-assistant/home-assistant:stable";
          pull = "newer";
          autoStart = true;
          privileged = true;
          capabilities = {
            NET_ADMIN = true;
            NET_RAW = true;
          };
          devices = [
            "/dev/bus/usb/001/002:/dev/bus/usb/001/002"
            "/dev/bus/usb/001/005:/dev/bus/usb/001/005"
          ];
          environment = {
            OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";
            OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
            OTEL_LOGS_EXPORTER = "otlp";
            OTEL_METRICS_EXPORTER = "otlp";
            OTEL_RESOURCE_ATTRIBUTES = "service.namespace=home-server,deployment.environment=home";
            OTEL_SERVICE_NAME = "home-assistant";
            OTEL_TRACES_EXPORTER = "otlp";
            TZ = "Europe/Brussels";
          };
          volumes = [
            "/var/lib/hass:/config"
            "/etc/localtime:/etc/localtime:ro"
            "/run/dbus:/run/dbus:ro"
          ];
          extraOptions = ["--network=host"];
        };
      };
    };

    systemd.services.podman-home-assistant.preStart = ''
      install -d -m 0700 /var/lib/hass

      if [ -L /var/lib/hass/configuration.yaml ]; then
        rm /var/lib/hass/configuration.yaml
      fi

      install -m 0644 ${configurationFile} /var/lib/hass/configuration.yaml
    '';
  };
}
