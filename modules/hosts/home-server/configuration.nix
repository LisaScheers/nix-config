{config, ...}: let
  flakeConfig = config;
in {
  localModules.nixos."home-server" = {
    config,
    flakeRevision,
    lib,
    ...
  }: {
    imports = [
      flakeConfig.localModules.nixos."auto-sync-update"
      flakeConfig.localModules.nixos."home-server-disk"
      ./_hardware-configuration.nix
      flakeConfig.localModules.nixos."home-server-acme"
      flakeConfig.localModules.nixos."home-server-ai-agent-sandbox"
      flakeConfig.localModules.nixos."home-server-base"
      flakeConfig.localModules.nixos."home-server-dns"
      flakeConfig.localModules.nixos."home-server-gotify"
      flakeConfig.localModules.nixos."home-server-home-assistant"
      flakeConfig.localModules.nixos."home-server-i2p"
      flakeConfig.localModules.nixos."home-server-media"
      flakeConfig.localModules.nixos."home-server-monitoring"
      flakeConfig.localModules.nixos."home-server-neo4j"
      flakeConfig.localModules.nixos."home-server-onepassword-connect"
      flakeConfig.localModules.nixos."home-server-second-life-cache"
      flakeConfig.localModules.nixos."home-server-siem"
      flakeConfig.localModules.nixos."home-server-vaultwarden"
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
  };
}
