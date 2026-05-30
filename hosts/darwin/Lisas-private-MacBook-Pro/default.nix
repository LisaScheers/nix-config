{
  withSystem,
  inputs,
  config,
  localConfig,
  ...
}: let
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
        withSystem
        ;
    };
    modules = [
      inputs.sops-nix.darwinModules.sops
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      ../../../modules/darwin
      ./configuration.nix
    ];
  };
}
