{
  inputs,
  pkgs,
  ...
}: let
  artifacts = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.remote-shell-artifacts;
in {
  services.nginx.virtualHosts."shell.bylisa.dev" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "= /" = {
        alias = "${artifacts}/bootstrap.sh";
        extraConfig = ''
          default_type text/plain;
          add_header Cache-Control "no-store" always;
          add_header X-Content-Type-Options "nosniff" always;
        '';
      };
      "/bundles/" = {
        alias = "${artifacts}/bundles/";
        extraConfig = ''
          default_type application/gzip;
          add_header Cache-Control "public, max-age=31536000, immutable" always;
          add_header X-Content-Type-Options "nosniff" always;
        '';
      };
    };
  };
}
