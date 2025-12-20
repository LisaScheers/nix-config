{
  config,
  pkgs,
  lib,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "lisa";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    git
    htop
    tree
    starship
    pnpm
    nodejs_24
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
  # direnv - automatically load/unload environment variables based on .envrc files
  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # Explicitly enable zsh integration
    enableBashIntegration = true; # Enable bash integration as well
    nix-direnv.enable = true; # Faster direnv with Nix support
    config = {
      # Global configuration for direnv
      global = {
        # Hide direnv output by default (can be verbose)
        hide_env_diff = true;
      };
    };
  };

  programs._1password-shell-plugins = {
    enable = true;
    plugins = with pkgs; [gh awscli2 cachix];
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lisa Scheers";
        email = "lisa@scheers.tech";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  # Shell configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      # Custom aliases
      alias ll='ls -lah'
      alias la='ls -A'
      alias l='ls -CF'
    '';
  };

  # env variables
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = 1;
    XDG_CONFIG_HOME = "$HOME/.config";
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    SOPS_AGE_KEY_CMD = "op item get ympq3ilboihqml7agfdb5ejxay --fields notesPlain --format=json | jq .value -r";
  };

  # Zsh configuration (common on macOS)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "docker" "kubectl"];
      theme = "robbyrussell";
    };
    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
    };
  };

  #nushell configuration
  programs.nushell = {
    enable = true;
    plugins = [
      pkgs.nushellPlugins.polars
      pkgs.nushellPlugins.formats
      pkgs.nushellPlugins.highlight
    ];
    settings = {
      show_banner = false;
    };
  };
}
