{config, ...}: let
  flakeConfig = config;
in {
  localModules.darwin.default = {
    imports = [
      flakeConfig.localModules.darwin."auto-sync-update"
      flakeConfig.localModules.darwin."home-manager"
      flakeConfig.localModules.darwin.homebrew
      flakeConfig.localModules.darwin.launchd
      flakeConfig.localModules.darwin.networking
      flakeConfig.localModules.darwin.nix
      flakeConfig.localModules.darwin.nixpkgs
      flakeConfig.localModules.darwin.packages
    ];
  };
}
