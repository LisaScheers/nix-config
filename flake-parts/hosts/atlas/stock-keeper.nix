{
  config,
  pkgs,
  ...
}:
{
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
    environmentFile = "/run/secrets/stock-keeper-env";
  };

  sops.secrets = {
    "stock-keeper-env" = {
      sopsFile = ../../../secrets/stock-keeper.env;
      owner = "stock-keeper";
      group = "stock-keeper";
      format = "dotenv";
    };
  };

  # Override nginx config to use wildcard certificate if available
  services.nginx.virtualHosts."stock-keeper.bylisa.dev" = {
    #useACMEHost = "wildcard.${config.networking.domain}";
    #forceSSL = true;
  };
}
