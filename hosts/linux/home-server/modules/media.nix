{
  config,
  lib,
  pkgs,
  ...
}: let
  certificateDomain = "media.local.bylisa.dev";
  jellyfinDomain = "jellyfin.local.bylisa.dev";
  prowlarrDomain = "prowlarr.local.bylisa.dev";
  radarrDomain = "radarr.local.bylisa.dev";
  sonarrDomain = "sonarr.local.bylisa.dev";
  transmissionDomain = "transmission.local.bylisa.dev";
  mediaRoot = "/srv/disks/western-digital-hdd/media";
  libraryRoot = "${mediaRoot}/library";
  downloadsRoot = "${mediaRoot}/downloads";
  mediaRoutingMark = "200";
  mediaServiceUsers = [
    "radarr"
    "sonarr"
    "prowlarr"
    "transmission"
  ];
  markUserCommands =
    lib.concatMapStringsSep "\n" (user: ''
      iptables -w -t mangle -D OUTPUT -m owner --uid-owner ${user} -j media-egress-vlan 2>/dev/null || true
      iptables -w -t mangle -A OUTPUT -m owner --uid-owner ${user} -j media-egress-vlan
      ip6tables -w -t mangle -D OUTPUT -m owner --uid-owner ${user} -j media-egress-vlan6 2>/dev/null || true
      ip6tables -w -t mangle -A OUTPUT -m owner --uid-owner ${user} -j media-egress-vlan6
    '')
    mediaServiceUsers;
  unmarkUserCommands =
    lib.concatMapStringsSep "\n" (user: ''
      iptables -w -t mangle -D OUTPUT -m owner --uid-owner ${user} -j media-egress-vlan 2>/dev/null || true
      ip6tables -w -t mangle -D OUTPUT -m owner --uid-owner ${user} -j media-egress-vlan6 2>/dev/null || true
    '')
    mediaServiceUsers;
  proxyErrorPage = import ./nginx-error-page.nix {inherit pkgs;};
  proxyHost = port:
    lib.mkMerge [
      proxyErrorPage
      {
        forceSSL = true;
        useACMEHost = certificateDomain;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      }
    ];
in {
  security.acme.certs.${certificateDomain} = {
    extraDomainNames = [
      jellyfinDomain
      prowlarrDomain
      radarrDomain
      sonarrDomain
      transmissionDomain
    ];
    extraLegoFlags = [
      "--dns.propagation-wait"
      "30s"
    ];
    group = "nginx";
    reloadServices = ["nginx.service"];
  };

  users.groups.media = {};
  users.users.prowlarr = {
    isSystemUser = true;
    group = "media";
    home = "${mediaRoot}/prowlarr";
  };

  systemd.tmpfiles.rules = [
    "d ${mediaRoot} 0775 root media -"
    "d ${libraryRoot} 0775 root media -"
    "d ${libraryRoot}/movies 0775 root media -"
    "d ${libraryRoot}/tv 0775 root media -"
    "d ${downloadsRoot} 0775 root media -"
    "d ${downloadsRoot}/complete 0775 transmission media -"
    "d ${downloadsRoot}/incomplete 0775 transmission media -"
    "d ${downloadsRoot}/watch 0775 transmission media -"
    "d ${mediaRoot}/jellyfin 0750 jellyfin media -"
    "d ${mediaRoot}/jellyfin/cache 0750 jellyfin media -"
    "d ${mediaRoot}/jellyfin/config 0750 jellyfin media -"
    "d ${mediaRoot}/jellyfin/data 0750 jellyfin media -"
    "d ${mediaRoot}/jellyfin/log 0750 jellyfin media -"
    "d ${mediaRoot}/prowlarr 0750 prowlarr media -"
    "d ${mediaRoot}/radarr 0750 radarr media -"
    "d ${mediaRoot}/sonarr 0750 sonarr media -"
    "d ${mediaRoot}/transmission 0750 transmission media -"
    "d ${mediaRoot}/transmission/.config 0750 transmission media -"
    "d ${mediaRoot}/transmission/.config/transmission-daemon 0750 transmission media -"
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
    cacheDir = "${mediaRoot}/jellyfin/cache";
    configDir = "${mediaRoot}/jellyfin/config";
    dataDir = "${mediaRoot}/jellyfin/data";
    logDir = "${mediaRoot}/jellyfin/log";
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    dataDir = "${mediaRoot}/radarr";
    settings = {
      update.mechanism = "external";
      server = {
        bindaddress = "*";
        port = 7878;
      };
    };
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
    dataDir = "${mediaRoot}/sonarr";
    settings = {
      update.mechanism = "external";
      server = {
        bindaddress = "*";
        port = 8989;
      };
    };
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
    dataDir = "${mediaRoot}/prowlarr";
    settings = {
      update.mechanism = "external";
      server = {
        bindaddress = "*";
        port = 9696;
      };
    };
  };

  services.transmission = {
    enable = true;
    group = "media";
    home = "${mediaRoot}/transmission";
    openPeerPorts = true;
    openRPCPort = true;
    downloadDirPermissions = "775";
    settings = {
      download-dir = "${downloadsRoot}/complete";
      incomplete-dir = "${downloadsRoot}/incomplete";
      incomplete-dir-enabled = true;
      peer-port = 51413;
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-whitelist = "127.0.0.1,192.168.*.*,100.*.*.*";
      rpc-whitelist-enabled = true;
      umask = 2;
      watch-dir = "${downloadsRoot}/watch";
      watch-dir-enabled = true;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      ${certificateDomain} = proxyHost 8096;
      ${jellyfinDomain} = proxyHost 8096;
      ${prowlarrDomain} = proxyHost 9696;
      ${radarrDomain} = proxyHost 7878;
      ${sonarrDomain} = proxyHost 8989;
      ${transmissionDomain} = proxyHost 9091;
    };
  };

  networking.firewall = {
    extraCommands = ''
      iptables -w -t mangle -N media-egress-vlan 2>/dev/null || true
      iptables -w -t mangle -F media-egress-vlan
      iptables -w -t mangle -A media-egress-vlan -d 0.0.0.0/8 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 10.0.0.0/8 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 100.64.0.0/10 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 127.0.0.0/8 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 169.254.0.0/16 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 172.16.0.0/12 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 192.168.0.0/16 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 224.0.0.0/4 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -d 240.0.0.0/4 -j RETURN
      iptables -w -t mangle -A media-egress-vlan -j MARK --set-mark ${mediaRoutingMark}

      ip6tables -w -t mangle -N media-egress-vlan6 2>/dev/null || true
      ip6tables -w -t mangle -F media-egress-vlan6
      ip6tables -w -t mangle -A media-egress-vlan6 -d ::1/128 -j RETURN
      ip6tables -w -t mangle -A media-egress-vlan6 -d fe80::/10 -j RETURN
      ip6tables -w -t mangle -A media-egress-vlan6 -d fc00::/7 -j RETURN
      ip6tables -w -t mangle -A media-egress-vlan6 -d ff00::/8 -j RETURN
      ip6tables -w -t mangle -A media-egress-vlan6 -d 2000::/3 -j MARK --set-mark ${mediaRoutingMark}

      ${markUserCommands}
    '';
    extraStopCommands = ''
      ${unmarkUserCommands}
      iptables -w -t mangle -F media-egress-vlan 2>/dev/null || true
      iptables -w -t mangle -X media-egress-vlan 2>/dev/null || true
      ip6tables -w -t mangle -F media-egress-vlan6 2>/dev/null || true
      ip6tables -w -t mangle -X media-egress-vlan6 2>/dev/null || true
    '';
  };

  systemd.services = {
    jellyfin.unitConfig.RequiresMountsFor = mediaRoot;
    radarr = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.RequiresMountsFor = mediaRoot;
      serviceConfig.UMask = lib.mkForce "0002";
    };
    sonarr = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.RequiresMountsFor = mediaRoot;
      serviceConfig.UMask = lib.mkForce "0002";
    };
    prowlarr = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.RequiresMountsFor = mediaRoot;
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        ExecStart = lib.mkForce "${config.services.prowlarr.package}/bin/Prowlarr -nobrowser -data=${mediaRoot}/prowlarr";
        Group = "media";
        StateDirectory = lib.mkForce "";
        UMask = "0002";
        User = "prowlarr";
      };
    };
    transmission = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.RequiresMountsFor = mediaRoot;
    };
  };
}
