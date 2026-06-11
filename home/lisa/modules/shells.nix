{
  config,
  pkgs,
  ...
}: let
  codexAlias = "nix run github:sadjow/codex-cli-nix -- --yolo";
  homeDirectory = config.home.homeDirectory;
in {
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    SOPS_AGE_KEY_CMD = "op item get ympq3ilboihqml7agfdb5ejxay --fields notesPlain --format=json | jq .value -r";
    SSH_AUTH_SOCK = "${homeDirectory}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
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
    plugins = with pkgs.nushellPlugins; [
      polars
      formats
      gstat
      query
      semver
    ];
    settings.show_banner = false;
    extraEnv = "alias codex = ${codexAlias}";
  };
}
