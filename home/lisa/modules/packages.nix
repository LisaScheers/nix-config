{pkgs, ...}: {
  home.packages = with pkgs; [
    git
    htop
    tree
    starship
    pnpm
    nodejs_24
  ];
}
