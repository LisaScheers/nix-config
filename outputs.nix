inputs: let
  localConfig = import ./config.nix;
in
  inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      ((import inputs.import-tree) ./modules)
    ];

    _module.args = {
      inherit localConfig;
    };
  }
