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
  nixosDiskDevices = {
    system = "/dev/disk/by-id/nvme-eui.002538ba71b63d8a";
    secondLifeCacheNvme = "/dev/disk/by-id/nvme-eui.00080d02000707ea";
    kingstonSsd = "/dev/disk/by-id/ata-KINGSTON_SUV400S37240G_50026B726406FC2C";
    westernDigitalHdd = "/dev/disk/by-id/wwn-0x50014ee261c9005d";
  };

  primaryUser = "lisa";
  primaryUserUid = 501;

  garbageCollectionAge = "14d";
  sopsAgeKeyFile = "/Users/lisa/.config/sops/age/keys.txt";
}
