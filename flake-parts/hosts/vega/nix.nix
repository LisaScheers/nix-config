{
  config,
  ...
}: let
  nookBuilderKeyPath = config.sops.secrets."nook-builder-ssh-key".path;
  nixGithubAccessTokenSystemPath = "/etc/nix/github-access-token.conf";
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
        hostName = "nook-builder";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        sshKey = nookBuilderKeyPath;
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
    extraOptions = ''
      !include ${nixGithubAccessTokenSystemPath}
    '';
  };

  sops.secrets = {
    "nook-builder-ssh-key" = {
      sopsFile = ../../secrets/vega/nix.sops.yaml;
      key = "builder_ssh_private_key";
      path = "/etc/nix/nook-builder";
      owner = "root";
      group = "staff";
      mode = "0600";
    };
    "nix-github-access-token" = {
      sopsFile = ../../secrets/vega/nix.sops.yaml;
      key = "github_access_token";
    };
  };

  sops.templates."nix-github-access-token-system.conf" = {
    path = nixGithubAccessTokenSystemPath;
    owner = "root";
    group = "staff";
    mode = "0400";
    content = ''
      access-tokens = github.com=${config.sops.placeholder."nix-github-access-token"}
    '';
  };

  sops.templates."nix-github-access-token-user.conf" = {
    path = "/run/secrets/nix/user-github-access-token.conf";
    owner = "lisa";
    group = "staff";
    mode = "0400";
    content = ''
      access-tokens = github.com=${config.sops.placeholder."nix-github-access-token"}
    '';
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

      Host nook-builder
        HostName 192.168.111.2
        User nix-remote-builder
        IdentityFile ${nookBuilderKeyPath}
        IdentitiesOnly yes
        HostKeyAlias 192.168.111.2
        BatchMode yes
    '';

    knownHosts.nook-builder = {
      hostNames = ["192.168.111.2"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHlf+pLT6XITnorOuDH0j9KtrVgZktsE5rPQzw3An8y";
    };
  };
}
