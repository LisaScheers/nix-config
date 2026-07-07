{...}: {
  localModules.home."lisa-files" = {
    xdg.configFile."alacritty/alacritty.toml".text = ''
      [terminal.shell]
      program = "/bin/zsh"
      args = ["-c", "nu"]

      [font]
      normal.family = "ComicCodeLigatures Nerd Font"
      bold.family = "ComicCodeLigatures Nerd Font"
      bold.style = "Bold"
      italic.family = "ComicCodeLigatures Nerd Font"
      italic.style = "Italic"
      bold_italic.family = "ComicCodeLigatures Nerd Font"
      bold_italic.style = "Bold Italic"

      [window]
      opacity = 0.9

      [colors.primary]
      # gray
      background = "#1e1e1e"
      # white
      foreground = "#ffffff"
    '';

    home.file = {
      ".config/git/allowed_signers".source = ./ssh/allowed-signers;
      ".ssh/SSH Key DevOps.pub".source = ./ssh/public-keys/ssh-key-devops.pub;
      ".ssh/ai-agent-sandbox.pub".source = ./ssh/public-keys/ai-agent-sandbox.pub;
      ".ssh/codeberg.pub".source = ./ssh/public-keys/codeberg.pub;
      ".ssh/dev.pub".source = ./ssh/public-keys/dev.pub;
      ".ssh/devops-odisee.pub".source = ./ssh/public-keys/devops-odisee.pub;
      ".ssh/home-server.pub".source = ./ssh/public-keys/home-server.pub;
    };
  };
}
