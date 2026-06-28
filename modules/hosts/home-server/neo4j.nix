{...}: {
  localModules.nixos."home-server-neo4j" = {
    lib,
    pkgs,
    ...
  }: let
    domain = "neo4j.local.bylisa.dev";
    storageRoot = "/srv/disks/western-digital-hdd/neo4j";
    httpAddress = "127.0.0.1";
    httpPort = 7474;
    boltAddress = "127.0.0.1";
    backendBoltPort = 17687;
    boltPort = 7687;
    browser = pkgs.runCommand "neo4j-browser" {nativeBuildInputs = [pkgs.unzip];} ''
      mkdir -p $out
      unzip -q ${pkgs.neo4j}/share/neo4j/web/neo4j-browser-*.zip -d $out
    '';
    proxyErrorPage = import ./_nginx-error-page.nix {inherit pkgs;};
  in {
    networking.firewall.allowedTCPPorts = [boltPort];

    services.cloudflare-dyndns.domains = [domain];

    security.acme.certs.${domain} = {
      extraLegoFlags = [
        "--dns.propagation-wait"
        "30s"
      ];
      group = "nginx";
      reloadServices = ["nginx.service"];
    };

    services.neo4j = {
      enable = true;
      directories.home = storageRoot;
      defaultListenAddress = "127.0.0.1";
      http = {
        enable = true;
        listenAddress = "${httpAddress}:${toString httpPort}";
        advertisedAddress = "${domain}:443";
      };
      https.enable = false;
      bolt = {
        enable = true;
        listenAddress = "${boltAddress}:${toString backendBoltPort}";
        advertisedAddress = "${domain}:${toString boltPort}";
        tlsLevel = "DISABLED";
      };
      extraServerConfig = ''
        server.default_advertised_address=${domain}
        browser.post_connect_cmd=config {theme: "dark"}
      '';
    };

    services.nginx.virtualHosts.${domain} = lib.mkMerge [
      proxyErrorPage
      {
        root = browser;
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = ''
          allow 192.168.50.0/24;
          allow 192.168.111.0/24;
          allow 2a02:1810:515:c682::/64;
          allow 2a02:1810:515:c680::/64;
          allow 100.64.0.0/10;
          allow fd7a:115c:a1e0::/48;
          allow 127.0.0.1;
          allow ::1;
          deny all;
        '';
        locations."= /".extraConfig = ''
          return 302 /browser/;
        '';
        locations."/browser/".extraConfig = ''
          try_files $uri $uri/ /browser/index.html;
        '';
        locations."/db/" = {
          proxyPass = "http://${httpAddress}:${toString httpPort}";
          proxyWebsockets = true;
        };
      }
    ];

    services.nginx.streamConfig = lib.mkAfter ''
      server {
        listen ${toString boltPort} ssl;
        listen [::]:${toString boltPort} ssl;
        proxy_pass ${boltAddress}:${toString backendBoltPort};
        proxy_timeout 1h;
        proxy_connect_timeout 10s;

        ssl_certificate /var/lib/acme/${domain}/fullchain.pem;
        ssl_certificate_key /var/lib/acme/${domain}/key.pem;

        allow 192.168.50.0/24;
        allow 192.168.111.0/24;
        allow 2a02:1810:515:c682::/64;
        allow 2a02:1810:515:c680::/64;
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        allow 127.0.0.1;
        allow ::1;
        deny all;
      }
    '';

    systemd.services.neo4j.unitConfig.RequiresMountsFor = storageRoot;
  };
}
