{...}: {
  localModules.home."lisa-packages" = {pkgs, ...}: {
    home.packages = with pkgs; [
      alacritty.terminfo
      git
      htop
      tree
      starship
      nix-output-monitor
      pnpm
      nodejs_24
    ];
  };
}
