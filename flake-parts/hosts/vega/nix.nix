{
  config,
  ...
}: let
  homeServerBuilderKeyPath = config.sops.secrets."home-server-builder-ssh-key".path;
  orbStackSshDir = "/Users/lisa/.orbstack/ssh";
in {
  nix = {
    enable = true;
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "orbstack-builder";
        protocol = "ssh-ng";
        system = "aarch64-linux";
      }
      {
        hostName = "home-server-builder";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        sshKey = homeServerBuilderKeyPath;
        maxJobs = 4;
        speedFactor = 1;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
    ];
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = ["lisa" "root"];
      builders-use-substitutes = true;
    };
  };

  sops.secrets."home-server-builder-ssh-key" = {
    sopsFile = ../../../secrets/home-server-builder-ssh-key.json;
    format = "json";
    key = "private_key";
    path = "/etc/nix/home-server-builder";
    owner = "root";
    group = "staff";
    mode = "0600";
  };

  programs.ssh = {
    extraConfig = ''
      Host orbstack-builder
        HostName 127.0.0.1
        Port 32222
        User default
        IdentityFile ${orbStackSshDir}/id_ed25519
        IdentitiesOnly yes
        UserKnownHostsFile ${orbStackSshDir}/known_hosts
        StrictHostKeyChecking yes
        BatchMode yes

      Host home-server-builder
        HostName 192.168.111.2
        User nix-remote-builder
        IdentityFile ${homeServerBuilderKeyPath}
        IdentitiesOnly yes
        HostKeyAlias 192.168.111.2
        BatchMode yes
    '';

    knownHosts.home-server-builder = {
      hostNames = ["192.168.111.2"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHlf+pLT6XITnorOuDH0j9KtrVgZktsE5rPQzw3An8y";
    };
  };
}
