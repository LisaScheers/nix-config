{
  config,
  pkgs,
  ...
}:
let
  secretsFile = ../../secrets/atlas/stock-keeper.sops.yaml;
in {
  services.stock-keeper = {
    enable = true;
    package = pkgs.stock-keeper;
    # These will be overridden by environmentFile, but are required by the module
    shopifyApiKey = "placeholder-will-be-overridden-by-env-file";
    shopifyApiSecret = "placeholder-will-be-overridden-by-env-file";
    shopifyAppUrl = "https://stock-keeper.bylisa.dev";
    enablePostgres = true;
    enableNginx = true;
    nginxHost = "stock-keeper.bylisa.dev";
    nginxEnableSSL = true;
    environmentFile = config.sops.templates."stock-keeper.env".path;
  };

  sops.secrets = {
    "stock-keeper/shopify-api-key" = {
      sopsFile = secretsFile;
      key = "shopify/api_key";
    };
    "stock-keeper/shopify-api-secret" = {
      sopsFile = secretsFile;
      key = "shopify/api_secret";
    };
  };

  sops.templates."stock-keeper.env" = {
    owner = "stock-keeper";
    group = "stock-keeper";
    content = ''
      SHOPIFY_API_KEY=${config.sops.placeholder."stock-keeper/shopify-api-key"}
      SHOPIFY_API_SECRET=${config.sops.placeholder."stock-keeper/shopify-api-secret"}
    '';
    restartUnits = [ "stock-keeper.service" ];
  };

  # Override nginx config to use wildcard certificate if available
  services.nginx.virtualHosts."stock-keeper.bylisa.dev" = {
    #useACMEHost = "wildcard.${config.networking.domain}";
    #forceSSL = true;
  };
}
