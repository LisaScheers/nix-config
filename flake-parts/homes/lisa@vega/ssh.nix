{config, ...}: let
  homeDirectory = config.home.homeDirectory;
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = ["~/.orbstack/ssh/config"];
    settings = {
      "codeberg.org" = {
        HostName = "codeberg.org";
        User = "git";
        IdentityFile = "~/.ssh/codeberg.pub";
        IdentitiesOnly = true;
      };

      "mail-hetzner" = {
        HostName = "100.121.88.128";
        User = "root";
        Port = 22;
        IdentityFile = "~/.ssh/hetzner";
        IdentitiesOnly = true;
      };

      "atlas" = {
        HostName = "91.99.142.26";
        User = "root";
        IdentityFile = "~/.ssh/hetzner-mc";
        IdentitiesOnly = true;
      };

      "nook" = {
        HostName = "192.168.111.2";
        User = "lisa";
        IdentityFile = "~/.ssh/home-server.pub";
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
        IdentityAgent = "\"${homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
    };
  };
}
