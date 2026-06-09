{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake = {
    nixosModules = {
      authentik = moduleWithSystem (
        perSystem @ {config}:
          import ./module.nix {
            inherit inputs;
          }
      );
    };
  };
}
