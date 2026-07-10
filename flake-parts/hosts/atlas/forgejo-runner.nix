{config, ...}: {
  virtualisation.docker.enable = true;

  services.forgejo-runner.instances.codeberg = {
    enable = true;
    name = "matrix.bylisa.dev";
    url = "https://codeberg.org/";
    uuid = "50b78075-8f82-49eb-94c8-ca2e0539b18a";
    tokenEnvironmentFile = config.age.secrets.forgejo-runner-token.path;
    labels = [
      "docker:docker://node:22-bookworm"
      "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
      "node-22:docker://node:22-bookworm"
      "nixos-latest:docker://nixos/nix"
    ];
  };

  age.secrets.forgejo-runner-token = {
    file = ../../agenix/secrets/atlas/forgejo-runner-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.services.forgejo-runner-codeberg.restartTriggers = [../../agenix/secrets/atlas/forgejo-runner-token.age];
}
