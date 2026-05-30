{
  flakeRevision,
  lib,
  ...
}: {
  imports = [
    ./modules/base
    ./modules/home-assistant.nix
  ];

  system.configurationRevision = lib.mkDefault flakeRevision;
  system.stateVersion = "25.11";
}
