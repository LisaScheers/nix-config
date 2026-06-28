{config, ...}: let
  flakeConfig = config;
in {
  flake.nixosModules = {
    authentik = flakeConfig.localModules.nixos.authentik;
    forgejo-runner = flakeConfig.localModules.nixos."forgejo-runner";
    matrix = flakeConfig.localModules.nixos.matrix;
  };
}
