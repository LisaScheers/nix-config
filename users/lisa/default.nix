{ config, pkgs, ... }:
{

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = [

  ];

  programs.git = {
    enable = true;
    userName = "Lisa Scheers";
    userEmail = "lisa@scheers.tech";
    extraConfig = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      init.defaultBranch = "main";

    };
  };

  programs.ssh = {
    enable = true;
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/1password"
    ];
    matchBlocks = {

    };
  };

  home.file = {
    _1password_ssh = {
      enable = true;
      text = ''
        Host *
        	IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
      target = ".ssh/1password";
    };
  };

  home.sessionVariables = {

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
