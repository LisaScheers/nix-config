{
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

  # add all .pub files in the ssh/public-keys directory to the home.file attribute set
  home.file = builtins.listToAttrs (map (key: {
    name = ".ssh/${key}";
    value = {
      source = ./ssh/public-keys/${key};
    };
  }) (builtins.filter (key: builtins.match ".*\\.pub" key != null) (builtins.attrNames (builtins.readDir ./ssh/public-keys))));
}
