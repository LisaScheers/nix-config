{
  config,
  flakeRevision,
  lib,
  ...
}: {
  imports = [
    ../../../modules/auto-sync-update.nix
    ./disk.nix
    ./hardware-configuration.nix
    ./modules/acme.nix
    ./modules/ai-agent-sandbox.nix
    ./modules/base
    ./modules/dns.nix
    ./modules/home-assistant.nix
    ./modules/monitoring.nix
    ./modules/neo4j.nix
    ./modules/onepassword-connect.nix
    ./modules/second-life-cache.nix
    ./modules/siem.nix
    ./modules/vaultwarden.nix
  ];

  services.autoSyncUpdate = {
    enable = true;
    flakeHost = "home-server";
    environmentFile = config.sops.secrets."auto-sync-update-env".path;
  };

  sops.secrets."auto-sync-update-env" = {
    sopsFile = ../../../secrets/auto-sync-update.env;
    format = "dotenv";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  system.configurationRevision = lib.mkDefault flakeRevision;
  system.stateVersion = "25.11";
}
