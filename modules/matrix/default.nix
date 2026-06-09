{
  lib,
  moduleWithSystem,
  ...
}: {
  flake = {
    nixosModules = {
      matrix = moduleWithSystem (
        perSystem @ {config}: import ./module.nix perSystem
      );
    };
  };
}
