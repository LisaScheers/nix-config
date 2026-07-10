{
  config,
  pkgs,
  ...
}: {
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
    environmentFile = config.age.secrets.stock-keeper-env.path;
  };

  age.secrets.stock-keeper-env = {
    file = ../../agenix/secrets/atlas/stock-keeper-env.age;
    owner = "stock-keeper";
    group = "stock-keeper";
    mode = "0400";
  };

  systemd.services.stock-keeper.restartTriggers = [../../agenix/secrets/atlas/stock-keeper-env.age];

  # Override nginx config to use wildcard certificate if available
  services.nginx.virtualHosts."stock-keeper.bylisa.dev" = {
    #useACMEHost = "wildcard.${config.networking.domain}";
    #forceSSL = true;
  };
}
