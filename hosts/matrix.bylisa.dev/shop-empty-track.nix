{config, ...}: {
  services.shop-empty-track = {
    enable = true;
    port = 3001;
    shopifyApiKey = "placeholder-will-be-overridden-by-env-file";
    shopifyApiSecret = "placeholder-will-be-overridden-by-env-file";
    shopifyAppUrl = "https://shop-empty-track.bylisa.dev";
    environmentFiles = ["/run/secrets/shop-empty-track-env"];

    nginx = {
      enable = true;
      hostName = "shop-empty-track.bylisa.dev";
      enableACME = true;
      forceSSL = true;
    };
  };

  sops.secrets = {
    "shop-empty-track-env" = {
      sopsFile = ../../secrets/shop-empty-track.env;
      owner = "shop-empty-track";
      group = "shop-empty-track";
      format = "dotenv";
    };
  };
}
