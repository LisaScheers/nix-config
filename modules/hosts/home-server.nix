{
  config,
  inputs,
  localConfig,
  ...
}: let
  flakeConfig = config;
in {
  flake.nixosConfigurations.${localConfig.nixosHost} = inputs.nixpkgs.lib.nixosSystem {
    system = localConfig.nixosSystem;
    specialArgs = {
      inputs = builtins.removeAttrs inputs ["self"];
      flakeRevision = inputs.self.rev or inputs.self.dirtyRev or null;
      inherit localConfig;
    };
    modules = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      flakeConfig.localModules.nixos."home-server"
    ];
  };
}
