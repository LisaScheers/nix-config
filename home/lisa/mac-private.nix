{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./default.nix
  ];

  home.homeDirectory = lib.mkForce "/Users/lisa"; # Darwin: /Users/lisa
}
