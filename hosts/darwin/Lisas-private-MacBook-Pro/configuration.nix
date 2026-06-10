{
  config,
  flakeRevision,
  lib,
  localConfig,
  ...
}: {
  system.primaryUser = localConfig.primaryUser;
  users.users.${localConfig.primaryUser}.uid = localConfig.primaryUserUid;

  security.pam.services.sudo_local.touchIdAuth = true;

  system.configurationRevision = lib.mkDefault flakeRevision;
  system.stateVersion = 6;

  nixpkgs.hostPlatform = localConfig.darwinSystem;

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = localConfig.sopsAgeKeyFile;
    secrets."auto-sync-update-env" = {
      sopsFile = ../../../secrets/auto-sync-update.env;
      format = "dotenv";
      owner = "root";
      group = "wheel";
      mode = "0400";
    };
  };

  services.autoSyncUpdate = {
    enable = true;
    flakeHost = localConfig.darwinHost;
    repositoryPath = localConfig.darwinFlakePath;
    environmentFile = config.sops.secrets."auto-sync-update-env".path;
  };
}
