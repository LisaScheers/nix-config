{config, ...}: let
  flakeConfig = config;
in {
  localModules.home."lisa-modules" = {
    imports = [
      flakeConfig.localModules.home."lisa-direnv"
      flakeConfig.localModules.home."lisa-files"
      flakeConfig.localModules.home."lisa-git"
      flakeConfig.localModules.home."lisa-onepassword"
      flakeConfig.localModules.home."lisa-packages"
      flakeConfig.localModules.home."lisa-shells"
      flakeConfig.localModules.home."lisa-ssh"
      flakeConfig.localModules.home."lisa-starship"
      flakeConfig.localModules.home."lisa-xdg"
    ];
  };
}
