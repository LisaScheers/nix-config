{
  config,
  inputs,
  localConfig,
  localKnownHosts,
  withSystem,
  ...
}: let
  flakeConfig = config;
  lisaMacosHomeModule = config.flake.homeModules.lisa-macos;
in {
  flake.darwinConfigurations.${localConfig.darwinHost} = inputs.nix-darwin.lib.darwinSystem {
    system = localConfig.darwinSystem;
    specialArgs = {
      inputs = builtins.removeAttrs inputs ["self"];
      flakeRevision = inputs.self.rev or inputs.self.dirtyRev or null;
      inherit
        lisaMacosHomeModule
        localConfig
        localKnownHosts
        withSystem
        ;
    };
    modules = [
      inputs.sops-nix.darwinModules.sops
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      flakeConfig.localModules.darwin."lisas-private-macbook-pro"
      flakeConfig.localModules.darwin.default
    ];
  };
}
