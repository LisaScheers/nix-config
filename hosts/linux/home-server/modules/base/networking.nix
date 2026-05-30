{localConfig, ...}: {
  networking = {
    hostName = localConfig.nixosHost;
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = [];
    };
  };

  time.timeZone = "Europe/Brussels";
}
