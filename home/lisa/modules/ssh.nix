{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = ["~/.orbstack/ssh/config"];
    settings = {
      "aws-moq" = {
        HostName = "13.51.254.84";
        User = "ec2-user";
        IdentityFile = "~/.ssh/moq-aws";
        IdentitiesOnly = true;
      };

      "devops-odisee" = {
        HostName = "ssh.dev.azure.com";
        User = "git";
        IdentityFile = "~/.ssh/devops-odisee.pub";
        IdentitiesOnly = true;
      };

      "mail" = {
        HostName = "dns.scheers.tech";
        User = "lisa";
        Port = 2222;
        PreferredAuthentications = "password";
      };

      "mail-hetzner" = {
        HostName = "188.245.70.181";
        User = "root";
        Port = 22;
        IdentityFile = "~/.ssh/hetzner";
        IdentitiesOnly = true;
      };

      "mail-hetzner-ts" = {
        HostName = "100.121.88.128";
        User = "root";
        Port = 22;
        IdentityFile = "~/.ssh/hetzner";
        IdentitiesOnly = true;
      };

      "mc" = {
        HostName = "91.99.142.26";
        User = "root";
        IdentityFile = "~/.ssh/hetzner-mc";
        IdentitiesOnly = true;
      };

      "dev" = {
        HostName = "89.169.108.115";
        User = "cloud";
        IdentityFile = "~/.ssh/dev.pub";
        IdentitiesOnly = true;
      };

      "router" = {
        HostName = "192.168.1.1";
        User = "root";
        PreferredAuthentications = "keyboard-interactive";
      };

      "matrix" = {
        HostName = "matrix.bylisa.dev";
        User = "lisa";
        IdentityFile = "~/.ssh/hetzner-mc";
        IdentitiesOnly = true;
      };

      "*" = {
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
    };
  };
}
