{inputs, ...}: {
  flake.darwinConfigurations."work" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {inputs = builtins.removeAttrs inputs ["self"];};
    modules = [
      inputs.sops-nix.darwinModules.sops
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      (_: {
        nix.enable = false;
        system.stateVersion = 6;
      })
    ];
  };
}
