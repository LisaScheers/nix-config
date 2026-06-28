{config, ...}: let
  flakeConfig = config;
in {
  localModules.nixos."home-server-base" = {
    imports = [
      flakeConfig.localModules.nixos."home-server-base-boot"
      flakeConfig.localModules.nixos."home-server-base-networking"
      flakeConfig.localModules.nixos."home-server-base-nix"
      flakeConfig.localModules.nixos."home-server-base-packages"
      flakeConfig.localModules.nixos."home-server-base-ssh"
      flakeConfig.localModules.nixos."home-server-base-sudo"
      flakeConfig.localModules.nixos."home-server-base-users"
    ];
  };
}
