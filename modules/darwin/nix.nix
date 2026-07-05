{...}: {
  localModules.darwin."nix" = {
    config,
    darwinHostConfig,
    lib,
    localConfig,
    ...
  }: let
    manageNix = darwinHostConfig.manageNix or true;
    homeServerBuilderKeyPath = config.sops.secrets."home-server-builder-ssh-key".path;
    orbStackSshDir = "/Users/${localConfig.primaryUser}/.orbstack/ssh";
  in {
    nix.enable = manageNix;

    nix.settings = lib.mkIf manageNix {
      experimental-features = "nix-command flakes";
      trusted-users = [localConfig.primaryUser];
      builders = lib.mkForce "@/etc/nix/machines";
      builders-use-substitutes = true;
    };

    sops.secrets."home-server-builder-ssh-key" = {
      sopsFile = ../../secrets/home-server-builder-ssh-key.json;
      format = "json";
      key = "private_key";
      path = "/etc/nix/home-server-builder";
      owner = "root";
      mode = "0600";
    };

    environment.etc."nix/machines".text = ''
      ssh-ng://orbstack-builder aarch64-linux
      ssh-ng://home-server-builder x86_64-linux ${homeServerBuilderKeyPath} 4 1 benchmark,big-parallel,kvm,nixos-test -
    '';

    environment.etc."ssh/ssh_config.d/101-nix-orbstack-builder.conf".text = ''
      Host orbstack-builder
        HostName 127.0.0.1
        Port 32222
        User default
        IdentityFile ${orbStackSshDir}/id_ed25519
        IdentitiesOnly yes
        UserKnownHostsFile ${orbStackSshDir}/known_hosts
        StrictHostKeyChecking yes
        BatchMode yes
    '';

    environment.etc."ssh/ssh_config.d/101-nix-home-server-builder.conf".text = ''
      Host home-server-builder
        HostName 192.168.111.2
        User nix-remote-builder
        IdentityFile ${homeServerBuilderKeyPath}
        IdentitiesOnly yes
        HostKeyAlias 192.168.111.2
        BatchMode yes
    '';

    system.activationScripts.postActivation.text = lib.mkIf (!manageNix) ''
      echo "removing unsupported Determinate Nix settings..." >&2

      nix_conf=/etc/nix/nix.conf
      nix_conf_tmp=$(mktemp /tmp/nix-darwin-nix-conf.XXXXXX)
      tmp_file=
      trap 'rm -f "$nix_conf_tmp" "''${tmp_file:-}"' EXIT

      if [ -f "$nix_conf" ]; then
        awk '$1 != "eval-cores" && $1 != "lazy-trees" { print }' "$nix_conf" > "$nix_conf_tmp"
        if ! cmp -s "$nix_conf" "$nix_conf_tmp"; then
          install -m 0644 "$nix_conf_tmp" "$nix_conf"
        fi
      fi

      echo "configuring Determinate Nix distributed builders..." >&2

      custom_conf=/etc/nix/nix.custom.conf
      begin_marker="# nix-darwin: distributed builders begin"
      end_marker="# nix-darwin: distributed builders end"
      tmp_file=$(mktemp /tmp/nix-darwin-nix-custom.XXXXXX)

      install -d -m 0755 /etc/nix

      if [ -f "$custom_conf" ]; then
        awk -v begin="$begin_marker" -v end="$end_marker" '
          $0 == begin { skip = 1; next }
          $0 == end { skip = 0; next }
          skip != 1 { print }
        ' "$custom_conf" > "$tmp_file"
      else
        : > "$tmp_file"
      fi

      cat >> "$tmp_file" <<'EOF'

      # nix-darwin: distributed builders begin
      builders = @/etc/nix/machines
      builders-use-substitutes = true
      # nix-darwin: distributed builders end
      EOF

      install -m 0644 "$tmp_file" "$custom_conf"
      rm -f "$tmp_file"
      trap - EXIT
    '';
  };
}
