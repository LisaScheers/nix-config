{...}: {
  localModules.nixos."matrix-host-mastodon" = {}: {
    services.mastodon = {
      enable = true;
      localDomain = "mastodon.bylisa.dev";
    };
  };
}
