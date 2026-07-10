inputs:
inputs.flake-parts.lib.mkFlake {inherit inputs;} {
  imports = [
    inputs.flake-file.flakeModules.default
    (inputs.flake-file.lib.flakeModules.flake-parts-builder ./flake-parts)
  ];
}
