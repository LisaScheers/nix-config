{pkgs, ...}: {
  home.packages = with pkgs; [
    claude-code
    claudex
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
