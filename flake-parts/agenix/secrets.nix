let
  keys = import ./pubkeys.nix;
  all = [
    keys.users.lisa
    keys.hosts.serverRoot
    keys.hosts.localMachine
  ];
  local = [
    keys.users.lisa
    keys.hosts.localMachine
  ];
in {
  "secrets/atlas/authentik-env.age".publicKeys = all;
  "secrets/atlas/authentik-ldap-outpost-env.age".publicKeys = all;
  "secrets/atlas/auto-sync-update-env.age".publicKeys = all;
  "secrets/atlas/bluesky-pds-env.age".publicKeys = all;
  "secrets/atlas/cf-api-token.age".publicKeys = all;
  "secrets/atlas/forgejo-runner-token.age".publicKeys = all;
  "secrets/atlas/matrix-registration-secret.age".publicKeys = all;
  "secrets/atlas/matrix-turn-secret.age".publicKeys = all;
  "secrets/atlas/monitoring-otlp-env.age".publicKeys = all;
  "secrets/atlas/shop-empty-track-env.age".publicKeys = all;
  "secrets/atlas/stock-keeper-env.age".publicKeys = all;

  "secrets/nook/cloudflare-dns-api-token.age".publicKeys = local;
  "secrets/nook/gotify-env.age".publicKeys = all;
  "secrets/nook/grafana-authentik-client-secret.age".publicKeys = local;
  "secrets/nook/monitoring-otlp-htpasswd.age".publicKeys = local;
  "secrets/nook/onepassword-connect-credentials.age".publicKeys = local;
  "secrets/nook/vaultwarden-admin-token-env.age".publicKeys = all;
  "secrets/nook/vaultwarden-env.age".publicKeys = all;
  "secrets/nook/vaultwarden-restic-env.age".publicKeys = all;
  "secrets/nook/vaultwarden-restic-ssh-key.age".publicKeys = all;

  "secrets/vega/home-server-builder-ssh-key.age".publicKeys = all;
  "secrets/vega/nix-github-access-token-conf.age".publicKeys = local;

  "secrets/shared/github-env.age".publicKeys = all;
}
