{
  lib,
  pkgs,
  ...
}: let
  containerName = "ai-agent-sandbox";
  imageName = "localhost/${containerName}";
  imageTag = "latest";
  serviceUser = "ai-agent-sandbox";
  serviceUid = 989;
  sshPort = 2223;
  projectsRoot = "/srv/disks/kingston-ssd/projects";
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFTAh/6Ikl8gWH9KFg5Ns6JLJg+Qw7laL3fTFVZiNQ7i";

  sandboxPackages = with pkgs; [
    bashInteractive
    cacert
    coreutils
    curl
    direnv
    findutils
    gawk
    git
    gnugrep
    gnused
    gzip
    jq
    less
    nano
    nix
    openssh
    procps
    python3
    ripgrep
    rsync
    shadow
    sudo
    gnutar
    vim
    wget
    which
    xz
    zstd
  ];

  sandboxPath = lib.makeBinPath sandboxPackages;

  sshdConfig = pkgs.writeText "ai-agent-sandbox-sshd_config" ''
    Port 22
    ListenAddress 0.0.0.0
    Protocol 2

    HostKey /etc/ssh/ssh_host_ed25519_key
    HostKey /etc/ssh/ssh_host_rsa_key

    PermitRootLogin prohibit-password
    PubkeyAuthentication yes
    AuthorizedKeysFile .ssh/authorized_keys
    AuthenticationMethods publickey
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PermitEmptyPasswords no
    UsePAM no

    AllowUsers root
    X11Forwarding no
    AllowAgentForwarding no
    AllowTcpForwarding no
    PermitTunnel no
    PermitUserEnvironment no
    DisableForwarding yes

    ClientAliveInterval 300
    ClientAliveCountMax 2
    LogLevel VERBOSE
    Subsystem sftp internal-sftp
  '';

  startSshd = pkgs.writeShellApplication {
    name = "ai-agent-sandbox-sshd";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
    ];
    text = ''
      set -eu

      install -d -m 0755 /etc/ssh /run/sshd /projects
      install -d -m 0700 /root /root/.ssh

      cat > /root/.ssh/authorized_keys <<'AUTHORIZED_KEYS'
      ${publicKey}
      AUTHORIZED_KEYS
      chmod 0600 /root/.ssh/authorized_keys

      if ! ls /etc/ssh/ssh_host_*_key >/dev/null 2>&1; then
        ssh-keygen -A
      fi

      cd /projects
      exec sshd -D -e -f ${sshdConfig}
    '';
  };

  sandboxImage = pkgs.dockerTools.streamLayeredImage {
    name = imageName;
    tag = imageTag;
    contents = sandboxPackages ++ [startSshd];
    extraCommands = ''
      mkdir -p etc/nix root projects tmp var/tmp var/empty

      cat > etc/passwd <<'EOF'
      root:x:0:0:root:/root:${pkgs.bashInteractive}/bin/bash
      nobody:x:65534:65534:nobody:/var/empty:${pkgs.shadow}/bin/nologin
      EOF

      cat > etc/group <<'EOF'
      root:x:0:
      nixbld:x:30000:
      nogroup:x:65534:
      EOF

      cat > etc/shadow <<'EOF'
      root:*:1::::::
      nobody:*:1::::::
      EOF

      cat > etc/nsswitch.conf <<'EOF'
      passwd: files
      group: files
      shadow: files
      hosts: files dns
      networks: files
      protocols: files
      services: files
      ethers: files
      rpc: files
      EOF

      cat > etc/nix/nix.conf <<'EOF'
      experimental-features = nix-command flakes
      sandbox = false
      EOF

      chmod 0600 etc/shadow
      chmod 1777 tmp var/tmp
      chmod 0700 root
    '';
    config = {
      Entrypoint = ["${startSshd}/bin/ai-agent-sandbox-sshd"];
      WorkingDir = "/projects";
      Env = [
        "PATH=${sandboxPath}"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_CONFIG=experimental-features = nix-command flakes"
      ];
      ExposedPorts."22/tcp" = {};
    };
  };
in {
  users.groups.${serviceUser}.gid = serviceUid;
  users.users.${serviceUser} = {
    isSystemUser = true;
    description = "Rootless Podman user for the AI agent SSH sandbox";
    group = serviceUser;
    uid = serviceUid;
    home = "/var/lib/${serviceUser}";
    createHome = true;
    homeMode = "0700";
    linger = true;
    autoSubUidGidRange = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/${serviceUser} 0700 ${serviceUser} ${serviceUser} -"
    "d ${projectsRoot} 0750 ${serviceUser} ${serviceUser} -"
  ];

  networking.firewall.allowedTCPPorts = [sshPort];

  virtualisation = {
    podman.enable = true;
    oci-containers = {
      backend = "podman";
      containers.${containerName} = {
        image = "${imageName}:${imageTag}";
        imageStream = sandboxImage;
        pull = "never";
        autoStart = true;
        podman.user = serviceUser;
        hostname = "ai-agent-sandbox";
        ports = [
          "192.168.111.2:${toString sshPort}:22/tcp"
        ];
        volumes = [
          "${projectsRoot}:/projects"
        ];
        workdir = "/projects";
        capabilities = {
          AUDIT_WRITE = false;
          MKNOD = false;
          NET_RAW = false;
          SYS_CHROOT = true;
        };
        extraOptions = [
          "--security-opt=no-new-privileges"
          "--pids-limit=512"
          "--memory=8g"
          "--cpus=4"
        ];
      };
    };
  };

  systemd.services.podman-ai-agent-sandbox.unitConfig.RequiresMountsFor = [
    "/var/lib/${serviceUser}"
    projectsRoot
  ];
}
