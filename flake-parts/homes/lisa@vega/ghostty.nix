{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    # Ghostty is installed system-wide with ghostty-bin because the source
    # package is not supported on Darwin.
    package = null;
    settings = {
      command = "direct:${lib.getExe pkgs.nushell}";
      env = ["XDG_CONFIG_HOME=${config.xdg.configHome}"];
      shell-integration-features = "sudo,ssh-env,ssh-terminfo,path";

      font-family = "ComicCodeLigatures Nerd Font";
      font-family-bold = "ComicCodeLigatures Nerd Font";
      font-style-bold = "Bold";
      font-family-italic = "ComicCodeLigatures Nerd Font";
      font-style-italic = "Italic";
      font-family-bold-italic = "ComicCodeLigatures Nerd Font";
      font-style-bold-italic = "Bold Italic";

      background-opacity = 0.9;
      background = "1e1e1e";
      foreground = "ffffff";
    };
  };
}
