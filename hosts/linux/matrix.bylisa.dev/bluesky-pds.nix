{config, ...}: {
  services.bluesky-pds = {
    enable = true;
    settings = {
      PDS_HOSTNAME = config.networking.domain;
      PDS_PORT = 4000;
    };
    pdsadmin = {
      enable = true;
    };
    environmentFiles = [
      "/run/secrets/bluesky-pds-env"
    ];
  };
  sops.secrets = {
    "bluesky-pds-env" = {
      sopsFile = ../../../secrets/bsky.env;
      owner = "root";
      group = "root";
      format = "dotenv";
    };
  };
  # virtual host for bluesky
  services.nginx.virtualHosts = {
    ${config.services.bluesky-pds.settings.PDS_HOSTNAME} = {
      locations = {
        "/" = {
          proxyPass = "http://[::1]:${toString config.services.bluesky-pds.settings.PDS_PORT}";
          proxyWebsockets = true;
        };
      };
      addSSL = true;
      enableACME = true;
    };
    "*.${config.networking.domain}" = {
      locations = {
        "/" = {
          proxyPass = "http://[::1]:${toString config.services.bluesky-pds.settings.PDS_PORT}";
          proxyWebsockets = true;
        };
      };
      addSSL = true;
      useACMEHost = "wildcard.${config.networking.domain}";
    };
  };

  security.acme.certs."wildcard.${config.networking.domain}" = {
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    environmentFile = "/run/secrets/cf-api-token";
    domain = "*.${config.networking.domain}";
    group = config.users.groups.nginx.name;
    webroot = null;
  };
  sops.secrets = {
    "cf-api-token" = {
      sopsFile = ../../../secrets/cf-token.env;
      owner = config.users.users.acme.name;
      group = config.users.groups.acme.name;
      format = "dotenv";
    };
  };
}
