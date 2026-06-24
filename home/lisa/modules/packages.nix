{pkgs, ...}: {
  home.packages = with pkgs; [
    git
    htop
    tree
    starship
    nix-output-monitor
    pnpm
    nodejs_24
  ];
}
