{
  flakeRevision,
  lib,
  ...
}: {
  imports = [
    ./disk.nix
    ./hardware-configuration.nix
    ./modules/acme.nix
    ./modules/base
    ./modules/home-assistant.nix
    ./modules/monitoring.nix
  ];

  system.configurationRevision = lib.mkDefault flakeRevision;
  system.stateVersion = "25.11";
}
