let
  keys = import ./pubkeys.nix;
  all = [
    keys.users.lisa
    keys.hosts.atlas
    keys.hosts.nook
    keys.hosts.vega
  ];
  nook = [
    keys.users.lisa
    keys.hosts.nook
  ];
  vega = [
    keys.users.lisa
    keys.hosts.vega
  ];
  mail = [
    keys.users.lisa
    keys.hosts.mail
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

  "secrets/nook/cloudflare-dns-api-token.age".publicKeys = nook;
  "secrets/nook/gotify-env.age".publicKeys = all;
  "secrets/nook/grafana-authentik-client-secret.age".publicKeys = nook;
  "secrets/nook/monitoring-otlp-htpasswd.age".publicKeys = nook;
  "secrets/nook/onepassword-connect-credentials.age".publicKeys = nook;
  "secrets/nook/vaultwarden-admin-token-env.age".publicKeys = all;
  "secrets/nook/vaultwarden-env.age".publicKeys = all;
  "secrets/nook/vaultwarden-restic-env.age".publicKeys = all;
  "secrets/nook/vaultwarden-restic-ssh-key.age".publicKeys = all;

  "secrets/vega/home-server-builder-ssh-key.age".publicKeys = all;
  "secrets/vega/nix-github-access-token-conf.age".publicKeys = vega;

  "secrets/shared/github-env.age".publicKeys = all;

  "secrets/mail/cloudflared-token.age".publicKeys = mail;
  "secrets/mail/app-passwords.age".publicKeys = mail;
  "secrets/mail/monitoring-otlp-env.age".publicKeys = mail;
  "secrets/mail/sogo-db-password.age".publicKeys = mail;
  "secrets/mail/sogo-encryption-key.age".publicKeys = mail;

  "secrets/mail/dkim-chiritsu-com.age".publicKeys = mail;
  "secrets/mail/dkim-clovercri-com.age".publicKeys = mail;
  "secrets/mail/dkim-icetokki-com.age".publicKeys = mail;
  "secrets/mail/dkim-scheers-tech.age".publicKeys = mail;

  "secrets/mail/password-allabs-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-auth-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-catchall-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-cyanna-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-hello-chiritsu-com.age".publicKeys = mail;
  "secrets/mail/password-info-clovercri-com.age".publicKeys = mail;
  "secrets/mail/password-lisa-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-matrix-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-nix-watchdog-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-pds-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-scan-scheers-tech.age".publicKeys = mail;
  "secrets/mail/password-tokki-icetokki-com.age".publicKeys = mail;
  "secrets/mail/password-vaultwarden-scheers-tech.age".publicKeys = mail;
}
