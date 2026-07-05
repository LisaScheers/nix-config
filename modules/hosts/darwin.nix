{
  config,
  inputs,
  lib,
  localConfig,
  localKnownHosts,
  withSystem,
  ...
}: let
  flakeConfig = config;
  lisaMacosHomeModule = config.flake.homeModules.lisa-macos;
  mkDarwinConfiguration = darwinHost: darwinHostConfig: let
    hostModuleName = darwinHostConfig.module or darwinHost;
  in
    inputs.nix-darwin.lib.darwinSystem {
      system = darwinHostConfig.system or localConfig.darwinSystem;
      specialArgs = {
        inputs = builtins.removeAttrs inputs ["self"];
        flakeRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        inherit
          darwinHost
          darwinHostConfig
          lisaMacosHomeModule
          localConfig
          localKnownHosts
          withSystem
          ;
      };
      modules =
        [
          inputs.sops-nix.darwinModules.sops
          inputs.home-manager.darwinModules.home-manager
          inputs.nix-homebrew.darwinModules.nix-homebrew
        ]
        ++ lib.optional (darwinHostConfig.useLix or false) inputs.lix-nixos-module.darwinModules.lixFromNixpkgs
        ++ [
          flakeConfig.localModules.darwin.${hostModuleName}
          flakeConfig.localModules.darwin.default
        ];
    };
in {
  flake.darwinConfigurations = lib.mapAttrs mkDarwinConfiguration localConfig.darwinHosts;
}
