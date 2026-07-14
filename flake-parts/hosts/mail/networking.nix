{
  networking = {
    useDHCP = false;
    nameservers = [
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
      "185.12.64.1"
      "185.12.64.2"
    ];
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.MACAddress = "92:00:06:07:83:3e";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
      };
      addresses = [
        {Address = "2a01:4f8:1c1e:ba3a::1/64";}
      ];
      routes = [
        {
          Gateway = "fe80::1";
          GatewayOnLink = true;
        }
      ];
    };
  };
}
