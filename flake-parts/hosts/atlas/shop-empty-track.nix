{config, ...}: let
  secretsFile = ../../secrets/atlas/shop-empty-track.sops.yaml;
in {
  services.shop-empty-track = {
    enable = true;
    port = 3001;
    shopifyApiKey = "placeholder-will-be-overridden-by-env-file";
    shopifyApiSecret = "placeholder-will-be-overridden-by-env-file";
    shopifyAppUrl = "https://shop-empty-track.bylisa.dev";
    environmentFiles = [ config.sops.templates."shop-empty-track.env".path ];

    nginx = {
      enable = true;
      hostName = "shop-empty-track.bylisa.dev";
      enableACME = true;
      forceSSL = true;
    };
  };

  sops.secrets = {
    "shop-empty-track/shopify-api-key" = {
      sopsFile = secretsFile;
      key = "shopify/api_key";
    };
    "shop-empty-track/shopify-api-secret" = {
      sopsFile = secretsFile;
      key = "shopify/api_secret";
    };
  };

  sops.templates."shop-empty-track.env" = {
    owner = "shop-empty-track";
    group = "shop-empty-track";
    content = ''
      SHOPIFY_API_KEY=${config.sops.placeholder."shop-empty-track/shopify-api-key"}
      SHOPIFY_API_SECRET=${config.sops.placeholder."shop-empty-track/shopify-api-secret"}
    '';
    restartUnits = [ "shop-empty-track.service" ];
  };
}
