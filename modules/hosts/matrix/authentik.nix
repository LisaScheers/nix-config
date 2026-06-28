{...}: {
  localModules.nixos."matrix-host-authentik" = {
    config,
    pkgs,
    ...
  }: let
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
      environmentFile = "/run/secrets/authentik-env";

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

    sops.secrets."authentik-env" = {
      sopsFile = ../../../secrets/authentik.env;
      owner = "root";
      group = "root";
      format = "dotenv";
    };

    sops.secrets."authentik-ldap-outpost-env" = {
      sopsFile = ../../../secrets/authentik-ldap-outpost.env;
      owner = "root";
      group = "root";
      format = "dotenv";
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
        config.sops.secrets."authentik-ldap-outpost-env".path
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
        EnvironmentFile = [config.sops.secrets."authentik-env".path];
        Environment = [
          "AUTHENTIK_CONFIG=/etc/authentik/config.yml"
        ];
        ExecStartPre = "${pkgs.coreutils}/bin/install -D -m 0600 ${grafanaBlueprint} %S/authentik/blueprints/grafana.yaml";
        ExecStart = "${config.services.authentik.package}/bin/ak apply_blueprint grafana.yaml";
      };
    };

    networking.firewall.allowedTCPPorts = [636];
  };
}
