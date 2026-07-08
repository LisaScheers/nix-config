{
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  darwinHost = "Lisas-private-MacBook-Pro";
  darwinSystem = "aarch64-darwin";
  darwinHosts = {
    "Lisas-private-MacBook-Pro" = {
      system = "aarch64-darwin";
      module = "lisas-private-macbook-pro";
      manageNix = false;
      computerName = "Lisas-private-MacBook-Pro";
      hostName = "Lisas-private-MacBook-Pro";
      localHostName = "Lisas-private-MacBook-Pro";
    };

    Vega = {
      system = "aarch64-darwin";
      module = "vega";
      manageNix = true;
      useLix = true;
      computerName = "Vega";
      hostName = "Vega";
      localHostName = "Vega";
    };
  };
  darwinFlakePath = "/private/etc/nix-darwin";
  darwinHomeDirectory = "/Users/lisa";

  nixosHost = "home-server";
  nixosDeployTarget = "lisa@192.168.111.2";
  nixosDeployRemoteDir = "/tmp/nix-config-deploy";
  nixosSystem = "x86_64-linux";

  primaryUser = "lisa";
  primaryUserUid = 501;

  garbageCollectionAge = "14d";
  sopsAgeKeyFile = "/Users/lisa/.config/sops/age/keys.txt";
}
