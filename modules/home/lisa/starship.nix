{...}: {
  localModules.home."lisa-starship" = {
    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./starship.toml);
    };
  };
}
