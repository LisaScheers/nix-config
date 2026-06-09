{
  lib,
  moduleWithSystem,
  ...
}: {
  flake = {
    nixosModules = {
      forgejo-runner = moduleWithSystem (
        perSystem @ {config}: import ./module.nix perSystem
      );
    };
  };
}
