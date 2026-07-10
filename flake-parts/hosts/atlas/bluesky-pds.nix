{ config, ... }:
let
  pdsSecrets = ../../secrets/atlas/bluesky-pds.sops.yaml;
  cloudflareSecrets = ../../secrets/atlas/cloudflare-acme.sops.yaml;
  pdsHostname = "matrix.bylisa.dev";
in
{
  services.bluesky-pds = {
    enable = true;
    settings = {
      PDS_HOSTNAME = pdsHostname;
      PDS_PORT = 4000;
    };
    pdsadmin = {
      enable = true;
    };
    environmentFiles = [
      config.sops.templates."bluesky-pds.env".path
    ];
  };

  sops.secrets = {
    "bluesky-pds/smtp-url" = {
      sopsFile = pdsSecrets;
      key = "email/smtp_url";
    };
    "bluesky-pds/email-from-address" = {
      sopsFile = pdsSecrets;
      key = "email/from_address";
    };
    "bluesky-pds/jwt-secret" = {
      sopsFile = pdsSecrets;
      key = "jwt_secret";
    };
    "bluesky-pds/admin-password" = {
      sopsFile = pdsSecrets;
      key = "admin_password";
    };
    "bluesky-pds/plc-rotation-key" = {
      sopsFile = pdsSecrets;
      key = "plc_rotation_key_k256_private_key_hex";
    };
    "atlas-cloudflare-dns-api-token" = {
      sopsFile = cloudflareSecrets;
      key = "dns_api_token";
      owner = config.users.users.acme.name;
      group = config.users.groups.acme.name;
    };
  };

  sops.templates."bluesky-pds.env" = {
    owner = "root";
    group = "root";
    content = ''
      PDS_EMAIL_SMTP_URL=${config.sops.placeholder."bluesky-pds/smtp-url"}
      PDS_EMAIL_FROM_ADDRESS=${config.sops.placeholder."bluesky-pds/email-from-address"}
      PDS_JWT_SECRET=${config.sops.placeholder."bluesky-pds/jwt-secret"}
      PDS_ADMIN_PASSWORD=${config.sops.placeholder."bluesky-pds/admin-password"}
      PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=${config.sops.placeholder."bluesky-pds/plc-rotation-key"}
    '';
    restartUnits = [ "bluesky-pds.service" ];
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
      forceSSL = true;
      enableACME = true;
    };
    "*.${pdsHostname}" = {
      locations = {
        "/" = {
          proxyPass = "http://[::1]:${toString config.services.bluesky-pds.settings.PDS_PORT}";
          proxyWebsockets = true;
        };
      };
      addSSL = true;
      useACMEHost = "wildcard.${pdsHostname}";
    };
  };

  security.acme.certs."wildcard.${pdsHostname}" = {
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    environmentFile = config.sops.templates."atlas-cloudflare-acme.env".path;
    domain = "*.${pdsHostname}";
    group = config.users.groups.nginx.name;
    webroot = null;
  };
  sops.templates."atlas-cloudflare-acme.env" = {
    owner = config.users.users.acme.name;
    group = config.users.groups.acme.name;
    content = ''
      CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."atlas-cloudflare-dns-api-token"}
    '';
  };
}
