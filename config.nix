{
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  darwinHost = "Lisas-private-MacBook-Pro";
  darwinSystem = "aarch64-darwin";
  darwinFlakePath = "/private/etc/nix-darwin";
  darwinHomeDirectory = "/Users/lisa";

  nixosHost = "home-server";
  nixosSystem = "x86_64-linux";

  primaryUser = "lisa";
  primaryUserUid = 501;

  garbageCollectionAge = "14d";
  sopsAgeKeyFile = "/Users/lisa/.config/sops/age/keys.txt";
}
