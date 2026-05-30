{
  config,
  pkgs,
  ...
}: let
  codexAlias = "nix run github:sadjow/codex-cli-nix -- --yolo";
in {
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    SOPS_AGE_KEY_CMD = "op item get ympq3ilboihqml7agfdb5ejxay --fields notesPlain --format=json | jq .value -r";
    SSH_AUTH_SOCK = "~/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases.codex = codexAlias;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases.codex = codexAlias;
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "docker" "kubectl"];
      theme = "robbyrussell";
    };
    dotDir = "${config.xdg.configHome}/zsh";
  };

  programs.nushell = {
    enable = true;
    plugins = [
      pkgs.nushellPlugins.polars
      pkgs.nushellPlugins.formats
      pkgs.nushellPlugins.gstat
      pkgs.nushellPlugins.query
    ];
    settings.show_banner = false;
    extraEnv = "alias codex = ${codexAlias}";
  };
}
