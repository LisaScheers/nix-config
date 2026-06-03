{config, ...}: {
  sops = {
    defaultSopsFile = ../../../../secrets/secrets.yaml;
    secrets."cloudflare-dns-api-token".key = "data/cloudflare-dns-api-token";
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "cloudflare";
      credentialFiles."CF_DNS_API_TOKEN_FILE" =
        config.sops.secrets."cloudflare-dns-api-token".path;
    };
  };
}
