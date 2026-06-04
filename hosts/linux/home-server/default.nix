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
    ./modules/dns.nix
    ./modules/home-assistant.nix
    ./modules/monitoring.nix
    ./modules/siem.nix
  ];

  system.configurationRevision = lib.mkDefault flakeRevision;
  system.stateVersion = "25.11";
}
