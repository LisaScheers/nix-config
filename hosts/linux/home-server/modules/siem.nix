{
  lib,
  pkgs,
  ...
}: let
  domain = "wazuh.local.bylisa.dev";
  version = "4.14.5";
  stateDir = "/var/lib/wazuh-docker";
  secretsDir = "/var/lib/wazuh-siem-secrets";
  workDir = "${stateDir}/single-node";
  unifiSyslogAllowedIps = "192.168.111.0/24";
  authentikMetadataUrl = "https://auth.bylisa.dev/api/v3/providers/saml/3/metadata/";
  proxyErrorPage = import ./nginx-error-page.nix {inherit pkgs;};
  compose = "${pkgs.docker-compose}/bin/docker-compose";
  unifiDecoder = pkgs.writeText "wazuh-unifi-decoder.xml" ''
    <decoder name="unifi-cef">
      <prematch type="pcre2">^CEF:\d+\|Ubiquiti\|UniFi Network\|</prematch>
      <regex type="pcre2">^CEF:\d+\|Ubiquiti\|UniFi Network\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|(.*)</regex>
      <order>unifi.version,unifi.event_id,unifi.event,unifi.severity,unifi.extension</order>
    </decoder>

    <decoder name="unifi-cef-syslog">
      <program_name>CEF</program_name>
      <prematch type="pcre2">^\d+\|Ubiquiti\|UniFi Network\|</prematch>
      <regex type="pcre2">^\d+\|Ubiquiti\|UniFi Network\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|(.*)</regex>
      <order>unifi.version,unifi.event_id,unifi.event,unifi.severity,unifi.extension</order>
    </decoder>
  '';
  unifiRules = pkgs.writeText "wazuh-unifi-rules.xml" ''
    <group name="unifi,ubiquiti,cef,">
      <rule id="110500" level="6">
        <decoded_as>unifi-cef</decoded_as>
        <description>UniFi event: $(unifi.event)</description>
      </rule>

      <rule id="110501" level="10">
        <if_sid>110500,110502</if_sid>
        <field name="unifi.event" type="pcre2">^(Admin Login Failed|Threat Detected|Blocked by Firewall|Honeypot Triggered)$</field>
        <description>UniFi security event: $(unifi.event)</description>
      </rule>

      <rule id="110502" level="6">
        <decoded_as>unifi-cef-syslog</decoded_as>
        <description>UniFi event: $(unifi.event)</description>
      </rule>
    </group>
  '';
  ensureWazuhRbac = pkgs.writeText "ensure-wazuh-saml-rbac.py" ''
    import base64
    import json
    import ssl
    import time
    import urllib.error
    import urllib.parse
    import urllib.request

    base = "https://127.0.0.1:55000"
    context = ssl._create_unverified_context()

    def request(method, path, data=None, token=None, basic=None):
        body = None if data is None else json.dumps(data).encode()
        headers = {"Accept": "application/json"}
        if data is not None:
            headers["Content-Type"] = "application/json"
        if token is not None:
            headers["Authorization"] = f"Bearer {token}"
        if basic is not None:
            headers["Authorization"] = "Basic " + base64.b64encode(basic.encode()).decode()
        req = urllib.request.Request(base + path, data=body, headers=headers, method=method)
        with urllib.request.urlopen(req, context=context, timeout=20) as response:
            raw = response.read().decode()
            return raw if not raw.startswith("{") else json.loads(raw)

    token = None
    for _ in range(90):
        try:
            token = request("POST", "/security/user/authenticate?raw=true", basic="wazuh-wui:MyS3cr37P450r.*-")
            break
        except (urllib.error.URLError, urllib.error.HTTPError):
            time.sleep(5)

    if not token:
        raise RuntimeError("Wazuh API did not become ready")

    rules = request("GET", "/security/rules", token=token)["data"]["affected_items"]
    rule_id = next((item["id"] for item in rules if item["name"] == "wazuh_saml_admins"), None)
    if rule_id is None:
        created = request(
            "POST",
            "/security/rules",
            {
                "name": "wazuh_saml_admins",
                "rule": {"FIND": {"backend_roles": "wazuh-admins"}},
            },
            token=token,
        )
        rule_id = created["data"]["affected_items"][0]["id"]

    roles = request("GET", "/security/roles", token=token)["data"]["affected_items"]
    role = next(item for item in roles if item["id"] == 1)
    if rule_id not in role["rules"]:
        query = urllib.parse.urlencode({"rule_ids": str(rule_id)})
        request("POST", f"/security/roles/1/rules?{query}", token=token)
  '';
  configureSaml = pkgs.writeText "configure-wazuh-saml.py" ''
    from pathlib import Path

    def lines(*items):
        return "\n".join(items) + "\n"

    exchange_key = Path("${secretsDir}/saml-exchange-key").read_text().strip()

    compose_path = Path("docker-compose.yml")
    compose = compose_path.read_text()
    compose = compose.replace('- "9200:9200"', '- "127.0.0.1:9200:9200"')
    compose = compose.replace('- "55000:55000"', '- "127.0.0.1:55000:55000"')
    compose = compose.replace('- 443:5601', '- 127.0.0.1:5601:5601')
    compose = compose.replace(
        '- "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"',
        '- "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g -Dorg.apache.xml.security.ignoreLineBreaks=true"',
    )
    manager_config_mount = "      - ./config/wazuh_cluster/wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf\n"
    unifi_manager_mounts = (
        "      - ./config/wazuh_cluster/local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml\n"
        "      - ./config/wazuh_cluster/local_rules.xml:/var/ossec/etc/rules/local_rules.xml\n"
    )
    if unifi_manager_mounts not in compose:
        compose = compose.replace(manager_config_mount, manager_config_mount + unifi_manager_mounts)
    indexer_mount = "      - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/config/opensearch-security/internal_users.yml\n"
    saml_mounts = (
        "      - ./config/wazuh_indexer/config.yml:/usr/share/wazuh-indexer/config/opensearch-security/config.yml\n"
        "      - ./config/wazuh_indexer/roles_mapping.yml:/usr/share/wazuh-indexer/config/opensearch-security/roles_mapping.yml\n"
        "      - ./config/wazuh_indexer/wazuh_authentik_meta.xml:/usr/share/wazuh-indexer/config/opensearch-security/wazuh_authentik_meta.xml\n"
        "      - ./config/wazuh_indexer/opensearch_security.policy:/usr/share/wazuh-indexer/config/opensearch-performance-analyzer/opensearch_security.policy\n"
        "      - ./config/wazuh_indexer/jvm.options:/usr/share/wazuh-indexer/config/jvm.options\n"
    )
    if saml_mounts not in compose:
        compose = compose.replace(indexer_mount, indexer_mount + saml_mounts)
    compose_path.write_text(compose)

    manager_config_path = Path("config/wazuh_cluster/wazuh_manager.conf")
    manager_config = manager_config_path.read_text()
    unifi_syslog_remote = lines(
        "  <remote>",
        "    <connection>syslog</connection>",
        "    <port>514</port>",
        "    <protocol>udp</protocol>",
        "    <allowed-ips>${unifiSyslogAllowedIps}</allowed-ips>",
        "  </remote>",
        "",
    )
    if "    <connection>syslog</connection>" not in manager_config:
        manager_config = manager_config.replace(
            lines(
                "  <remote>",
                "    <connection>secure</connection>",
                "    <port>1514</port>",
                "    <protocol>tcp</protocol>",
                "    <queue_size>131072</queue_size>",
                "  </remote>",
                "",
            ),
            lines(
                "  <remote>",
                "    <connection>secure</connection>",
                "    <port>1514</port>",
                "    <protocol>tcp</protocol>",
                "    <queue_size>131072</queue_size>",
                "  </remote>",
                "",
            )
            + unifi_syslog_remote,
        )
    manager_config_path.write_text(manager_config)

    config_path = Path("config/wazuh_indexer/config.yml")
    config = config_path.read_text()
    config = config.replace(
        lines(
            '      basic_internal_auth_domain:',
            '        description: "Authenticate via HTTP Basic against internal users database"',
            '        http_enabled: true',
            '        transport_enabled: true',
            '        order: 4',
            '        http_authenticator:',
            '          type: basic',
            '          challenge: true',
            '        authentication_backend:',
            '          type: intern',
        ),
        lines(
            '      basic_internal_auth_domain:',
            '        description: "Authenticate via HTTP Basic against internal users database"',
            '        http_enabled: true',
            '        transport_enabled: true',
            '        order: 0',
            '        http_authenticator:',
            '          type: basic',
            '          challenge: false',
            '        authentication_backend:',
            '          type: intern',
        ),
    )
    saml_domain = lines(
        '      saml_auth_domain:',
        '        http_enabled: true',
        '        transport_enabled: false',
        '        order: 1',
        '        http_authenticator:',
        '          type: saml',
        '          challenge: true',
        '          config:',
        '            idp:',
        "              metadata_file: '/usr/share/wazuh-indexer/config/opensearch-security/wazuh_authentik_meta.xml'",
        "              entity_id: 'wazuh-saml'",
        '            sp:',
        "              entity_id: 'wazuh-saml'",
        '            kibana_url: https://wazuh.local.bylisa.dev',
        '            roles_key: Roles',
        f"            exchange_key: '{exchange_key}'",
        '        authentication_backend:',
        '          type: noop',
    )
    if "      saml_auth_domain:" not in config:
        config = config.replace("      proxy_auth_domain:\n", saml_domain + "      proxy_auth_domain:\n")
    config_path.write_text(config)

    roles_path = Path("config/wazuh_indexer/roles_mapping.yml")
    roles = roles_path.read_text()
    roles = roles.replace(
        lines(
            'all_access:',
            '  reserved: true',
            '  hidden: false',
            '  backend_roles:',
            '  - "admin"',
        ),
        lines(
            'all_access:',
            '  reserved: true',
            '  hidden: false',
            '  backend_roles:',
            '  - "admin"',
            '  - "wazuh-admins"',
        ),
    )
    roles_path.write_text(roles)

    dashboard_path = Path("config/wazuh_dashboard/opensearch_dashboards.yml")
    dashboard = dashboard_path.read_text()
    if "opensearch_security.auth.multiple_auth_enabled:" not in dashboard:
        dashboard = dashboard.rstrip() + "\n" + lines(
            'opensearch_security.auth.multiple_auth_enabled: true',
            'opensearch_security.auth.type: ["basicauth","saml"]',
            'server.xsrf.allowlist: ["/_opendistro/_security/saml/acs", "/_opendistro/_security/saml/logout", "/_opendistro/_security/saml/acs/idpinitiated"]',
        )
    dashboard_path.write_text(dashboard)

    policy_path = Path("config/wazuh_indexer/opensearch_security.policy")
    policy = policy_path.read_text()
    if "org.apache.xml.security.ignoreLineBreaks" not in policy:
        policy = policy.rstrip() + "\n\n" + lines(
            "grant {",
            '  permission java.util.PropertyPermission "org.apache.xml.security.ignoreLineBreaks", "read,write";',
            "};",
        )
    policy_path.write_text(policy)

    jvm_path = Path("config/wazuh_indexer/jvm.options")
    jvm_options = jvm_path.read_text()
    jvm_options = jvm_options.replace(
        "-Djava.security.policy=file:///usr/share/wazuh-indexer/opensearch-performance-analyzer/opensearch_security.policy",
        "-Djava.security.policy=file:///usr/share/wazuh-indexer/config/opensearch-performance-analyzer/opensearch_security.policy",
    )
    jvm_path.write_text(jvm_options)
  '';
  prepare = pkgs.writeShellScript "prepare-wazuh-siem" ''
        set -euo pipefail

        install -d -m 0755 ${stateDir}
        install -d -m 0700 ${secretsDir}

        if [ ! -d ${stateDir}/.git ]; then
          if [ -n "$(find ${stateDir} -mindepth 1 -maxdepth 1 -print -quit)" ]; then
            echo "${stateDir} exists but is not a Wazuh Docker git checkout" >&2
            exit 1
          fi
          git clone --branch v${version} --depth 1 https://github.com/wazuh/wazuh-docker.git ${stateDir}
        fi

        cd ${stateDir}
        git fetch --depth 1 origin tag v${version}
        git checkout --quiet v${version}
        git reset --hard --quiet v${version}

        cd ${workDir}

        if [ ! -f ${secretsDir}/saml-exchange-key ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 32 > ${secretsDir}/saml-exchange-key
          chmod 0600 ${secretsDir}/saml-exchange-key
        fi

        ${pkgs.docker}/bin/docker pull -q wazuh/wazuh-indexer:${version} >/dev/null
        ${pkgs.docker}/bin/docker run --rm --entrypoint cat wazuh/wazuh-indexer:${version} \
          /usr/share/wazuh-indexer/config/opensearch-security/config.yml \
          > config/wazuh_indexer/config.yml
        ${pkgs.docker}/bin/docker run --rm --entrypoint cat wazuh/wazuh-indexer:${version} \
          /usr/share/wazuh-indexer/config/opensearch-security/roles_mapping.yml \
          > config/wazuh_indexer/roles_mapping.yml
        ${pkgs.docker}/bin/docker run --rm --entrypoint cat wazuh/wazuh-indexer:${version} \
          /usr/share/wazuh-indexer/config/opensearch-performance-analyzer/opensearch_security.policy \
          > config/wazuh_indexer/opensearch_security.policy
        ${pkgs.docker}/bin/docker run --rm --entrypoint cat wazuh/wazuh-indexer:${version} \
          /usr/share/wazuh-indexer/config/jvm.options \
          > config/wazuh_indexer/jvm.options

    install -D -m 0644 ${unifiDecoder} config/wazuh_cluster/local_decoder.xml
    install -D -m 0644 ${unifiRules} config/wazuh_cluster/local_rules.xml

    ${pkgs.curl}/bin/curl -fsSL ${authentikMetadataUrl} \
      | ${pkgs.python3}/bin/python3 -c 'import json,sys; sys.stdout.write(json.load(sys.stdin)["metadata"])' \
      > config/wazuh_indexer/wazuh_authentik_meta.xml

    ${pkgs.python3}/bin/python3 ${configureSaml}

    if [ ! -f config/wazuh_indexer_ssl_certs/root-ca.pem ]; then
      ${compose} -f generate-indexer-certs.yml run --rm generator
        fi
  '';
  stop = pkgs.writeShellScript "stop-wazuh-siem" ''
    set -euo pipefail

    if [ -d ${workDir} ]; then
      cd ${workDir}
      ${compose} down
    fi
  '';
in {
  boot.kernel.sysctl."vm.max_map_count" = 262144;

  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
  ];

  networking.firewall = {
    allowedTCPPorts = [
      1514
      1515
    ];
    allowedUDPPorts = [514];
  };

  services.cloudflare-dyndns.domains = [domain];

  security.acme.certs.${domain} = {
    extraLegoFlags = [
      "--dns.propagation-wait"
      "30s"
    ];
    group = "nginx";
    reloadServices = ["nginx.service"];
  };

  services.nginx.virtualHosts.${domain} = lib.mkMerge [
    proxyErrorPage
    {
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
      locations."/" = {
        proxyPass = "https://127.0.0.1:5601";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_ssl_verify off;
          proxy_ssl_server_name on;
        '';
      };
    }
  ];

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root -"
    "d ${secretsDir} 0700 root root -"
  ];

  systemd.services.wazuh-siem = {
    description = "Wazuh SIEM single-node Docker stack";
    wantedBy = ["multi-user.target"];
    requires = ["docker.service"];
    after = [
      "docker.service"
      "network-online.target"
    ];
    wants = ["network-online.target"];
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.docker
      pkgs.docker-compose
      pkgs.git
      pkgs.gnused
      pkgs.python3
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = prepare;
      ExecStop = stop;
      TimeoutStartSec = 0;
    };
    script = ''
      cd ${workDir}
      ${compose} up -d

      for _ in $(seq 1 90); do
        if ${pkgs.curl}/bin/curl -sk --fail -u admin:SecretPassword https://127.0.0.1:9200/_cluster/health >/dev/null; then
          break
        fi
        sleep 5
      done

      # OpenSearch can answer health checks before the security plugin finishes reloading SAML metadata.
      sleep 20

      securityadmin() {
        ${compose} exec -T wazuh.indexer bash -lc "export JAVA_HOME=/usr/share/wazuh-indexer/jdk && bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -f /usr/share/wazuh-indexer/config/opensearch-security/$1 -icl -key /usr/share/wazuh-indexer/config/certs/admin-key.pem -cert /usr/share/wazuh-indexer/config/certs/admin.pem -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem -h localhost -nhnv"
      }

      securityadmin config.yml
      securityadmin roles_mapping.yml
      ${pkgs.python3}/bin/python3 ${ensureWazuhRbac}
    '';
  };
}
