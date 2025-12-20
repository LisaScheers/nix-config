{
  inputs,
  lib,
}: {
  flake.darwinConfigurations."work" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {inherit inputs;};
    modules = [
      inputs.sops-nix.darwinModules.sops
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      ({
        pkgs,
        lib,
        ...
      }: {
        nix.enable = false;
        environment.systemPackages = [
        ];
      })
    ];
  };
}
