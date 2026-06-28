{
  config,
  inputs,
  ...
}: let
  flakeConfig = config;
in {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake.homeModules.lisa-macos = {
    imports = [
      inputs.onepassword-shell-plugins.hmModules.default
      flakeConfig.localModules.home."lisa-macos"
    ];
  };
}
