{config, ...}: let
  flakeConfig = config;
in {
  localModules.nixos."matrix-host" = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      flakeConfig.localModules.nixos."auto-sync-update"
      flakeConfig.localModules.nixos."matrix-host-hardware"
      flakeConfig.localModules.nixos."matrix-host-disko-config"
      flakeConfig.localModules.nixos."matrix-host-bluesky-pds"
      flakeConfig.localModules.nixos."matrix-host-minecraft"
      # flakeConfig.localModules.nixos."matrix-host-stock-keeper"
      flakeConfig.localModules.nixos."matrix-host-forgejo-runner"
      flakeConfig.localModules.nixos."matrix-host-authentik"
      flakeConfig.localModules.nixos."matrix-host-monitoring"
      flakeConfig.localModules.nixos."matrix-host-vaultwarden-backup"
    ];
  };
}
