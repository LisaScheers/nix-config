{pkgs, ...}: {
  home.packages = with pkgs; [
    ghostty-bin.terminfo
    git
    htop
    tree
    starship
    nix-output-monitor
    pnpm
    nodejs_24
  ];
}
