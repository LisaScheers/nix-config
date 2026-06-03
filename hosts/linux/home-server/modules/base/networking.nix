{localConfig, ...}: {
  networking = {
    hostName = localConfig.nixosHost;
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = [];
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-uplink" = {
        matchConfig.Name = "enp7s0";
        address = ["192.168.111.2/24"];
        gateway = ["192.168.111.1"];
        dns = ["192.168.111.1"];
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
        };
        ipv6AcceptRAConfig.UseDNS = true;
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };

  time.timeZone = "Europe/Brussels";
}
