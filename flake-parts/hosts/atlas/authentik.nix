{
  config,
  pkgs,
  ...
}: let
  authentikSecrets = ../../secrets/atlas/authentik.sops.yaml;
  grafanaSecrets = ../../secrets/shared/grafana-authentik.sops.yaml;
  grafanaBlueprint = pkgs.writeText "authentik-grafana-blueprint.yaml" ''
    version: 1

    metadata:
      name: Grafana OAuth2/OIDC

    entries:
      - model: authentik_providers_oauth2.oauth2provider
        identifiers:
          name: Grafana
        id: grafana-provider
        attrs:
          authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
          invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
          client_type: confidential
          grant_types:
            - authorization_code
          client_id: grafana
          client_secret: !Env GRAFANA_CLIENT_SECRET
          redirect_uris:
            - matching_mode: strict
              url: https://grafana.bylisa.dev/login/generic_oauth
            - matching_mode: strict
              url: https://grafana.local.bylisa.dev/login/generic_oauth
          logout_uri: https://grafana.bylisa.dev/logout
          logout_method: frontchannel
          property_mappings:
            - !Find [authentik_providers_oauth2.scopemapping, [name, "authentik default OAuth Mapping: OpenID 'openid'"]]
            - !Find [authentik_providers_oauth2.scopemapping, [name, "authentik default OAuth Mapping: OpenID 'email'"]]
            - !Find [authentik_providers_oauth2.scopemapping, [name, "authentik default OAuth Mapping: OpenID 'profile'"]]

      - model: authentik_core.application
        identifiers:
          slug: grafana
        attrs:
          name: Grafana
          provider: !KeyOf grafana-provider
  '';
in {
  services.authentik = {
    enable = true;
    environmentFile = config.sops.templates."authentik.env".path;

    settings = {
      email = {
        host = "m.scheers.tech";
        port = 587;
        use_tls = true;
        use_ssl = false;
        from = "auth@scheers.tech";
      };
      disable_startup_analytics = true;
      avatars = "initials";
      blueprints_dir = "/var/lib/authentik/blueprints";
    };

    nginx = {
      enable = true;
      enableACME = true;
      host = "auth.bylisa.dev";
    };
  };

  sops.secrets = {
    "authentik/secret-key" = {
      sopsFile = authentikSecrets;
      key = "secret_key";
    };
    "authentik/email-username" = {
      sopsFile = authentikSecrets;
      key = "email/username";
    };
    "authentik/email-password" = {
      sopsFile = authentikSecrets;
      key = "email/password";
    };
    "authentik/ldap-token" = {
      sopsFile = authentikSecrets;
      key = "ldap_outpost/token";
    };
    "grafana-authentik-client-secret" = {
      sopsFile = grafanaSecrets;
      key = "client_secret";
    };
  };

  sops.templates."authentik.env" = {
    owner = "root";
    group = "root";
    content = ''
      AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secret-key"}
      AUTHENTIK_EMAIL__USERNAME=${config.sops.placeholder."authentik/email-username"}
      AUTHENTIK_EMAIL__PASSWORD=${config.sops.placeholder."authentik/email-password"}
      GRAFANA_CLIENT_SECRET=${config.sops.placeholder."grafana-authentik-client-secret"}
    '';
    restartUnits = [
      "authentik.service"
      "authentik-worker.service"
      "authentik-grafana-blueprint.service"
    ];
  };

  sops.templates."authentik-ldap-outpost.env" = {
    owner = "root";
    group = "root";
    content = ''
      AUTHENTIK_TOKEN=${config.sops.placeholder."authentik/ldap-token"}
    '';
    restartUnits = [ "docker-authentik-ldap-outpost.service" ];
  };

  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.authentik-ldap-outpost = {
    image = "ghcr.io/goauthentik/ldap:2025.12.4";
    autoStart = true;
    environment = {
      AUTHENTIK_HOST = "https://auth.bylisa.dev";
      AUTHENTIK_INSECURE = "false";
    };
    environmentFiles = [
      config.sops.templates."authentik-ldap-outpost.env".path
    ];
    ports = [
      "636:6636"
    ];
  };

  systemd.services.authentik-grafana-blueprint = {
    description = "Apply Grafana Authentik OAuth2/OIDC blueprint";
    requiredBy = ["authentik.service"];
    before = ["authentik.service"];
    after = ["authentik-migrate.service"];
    requires = ["authentik-migrate.service"];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      User = "authentik";
      StateDirectory = "authentik";
      WorkingDirectory = "%S/authentik";
      EnvironmentFile = [config.sops.templates."authentik.env".path];
      Environment = [
        "AUTHENTIK_CONFIG=/etc/authentik/config.yml"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/install -D -m 0600 ${grafanaBlueprint} %S/authentik/blueprints/grafana.yaml";
      ExecStart = "${config.services.authentik.package}/bin/ak apply_blueprint grafana.yaml";
    };
  };

  networking.firewall.allowedTCPPorts = [636];
}
