{
  config,
  localConfig,
  ...
}: let
  homeServerBuilderKeyPath = config.sops.secrets."home-server-builder-ssh-key".path;
in {
  nix.enable = false;

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [localConfig.primaryUser];
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
    ssh-ng://orb aarch64-linux
    ssh-ng://nix-remote-builder@192.168.111.2 x86_64-linux ${homeServerBuilderKeyPath} 4 1 benchmark,big-parallel,kvm,nixos-test -
  '';

  system.activationScripts.postActivation.text = ''
    echo "configuring Nix distributed builders..." >&2

    custom_conf=/etc/nix/nix.custom.conf
    begin_marker="# nix-darwin: distributed builders begin"
    end_marker="# nix-darwin: distributed builders end"
    tmp_file=$(mktemp /tmp/nix-darwin-nix-custom.XXXXXX)
    trap 'rm -f "$tmp_file"' EXIT

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
}
