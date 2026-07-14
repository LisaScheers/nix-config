{
  config,
  lib,
  pkgs,
  ...
}: {
  age.secrets.cloudflared-token = {
    file = ../../agenix/secrets/mail/cloudflared-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.services.cloudflared = {
    description = "Cloudflare tunnel for mail web services";
    after = ["network-online.target" "nginx.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "notify";
      DynamicUser = true;
      LoadCredential = "token:${config.age.secrets.cloudflared-token.path}";
      ExecStart = "${lib.getExe pkgs.cloudflared} --no-autoupdate tunnel run --token-file %d/token";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "30s";
    };
  };
}
