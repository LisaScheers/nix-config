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
        HostName = "100.87.26.75";
        User = "root";
        IdentityFile = "~/.ssh/hetzner-mc";
        IdentitiesOnly = true;
      };

      "nook" = {
        HostName = "100.106.233.104";
        User = "lisa";
        IdentityFile = "~/.ssh/home-server.pub";
        IdentitiesOnly = true;
      };

      "router" = {
        HostName = "192.168.1.1";
        User = "root";
        PreferredAuthentications = "keyboard-interactive";
      };

      "*" = {
        IdentityAgent = "\"${homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
    };
  };
}
