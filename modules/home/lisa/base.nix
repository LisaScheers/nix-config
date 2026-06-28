{config, ...}: let
  flakeConfig = config;
in {
  localModules.home."lisa-base" = {localConfig, ...}: {
    imports = [
      flakeConfig.localModules.home."lisa-modules"
    ];

    home.username = localConfig.primaryUser;

    home.stateVersion = "25.11";

    xdg.enable = true;

    programs.home-manager.enable = true;
    manual.manpages.enable = false;
  };
}
