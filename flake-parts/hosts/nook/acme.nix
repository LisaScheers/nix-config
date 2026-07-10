{config, ...}: let
  secretsFile = ../../secrets/nook/cloudflare-acme.sops.yaml;
in {
  sops.secrets."cloudflare-dns-api-token" = {
    sopsFile = secretsFile;
    key = "dns_api_token";
    restartUnits = [ "cloudflare-dyndns.service" ];
  };

  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets."cloudflare-dns-api-token".path;
    domains = [
      "grafana.bylisa.dev"
      "grafana.local.bylisa.dev"
      "ha.bylisa.dev"
      "ha.local.bylisa.dev"
    ];
    ipv4 = true;
    ipv6 = true;
    proxied = false;
  };

  security.acme = {
    acceptTerms = true;
    certs."grafana.bylisa.dev" = {
      extraDomainNames = ["grafana.local.bylisa.dev"];
      extraLegoFlags = [
        "--dns.propagation-wait"
        "30s"
      ];
      group = "nginx";
      reloadServices = ["nginx.service"];
    };
    certs."ha.bylisa.dev" = {
      extraDomainNames = ["ha.local.bylisa.dev"];
      extraLegoFlags = [
        "--dns.propagation-wait"
        "30s"
      ];
      group = "nginx";
      reloadServices = ["nginx.service"];
    };
    defaults = {
      dnsProvider = "cloudflare";
      credentialFiles."CF_DNS_API_TOKEN_FILE" =
        config.sops.secrets."cloudflare-dns-api-token".path;
    };
  };
}
