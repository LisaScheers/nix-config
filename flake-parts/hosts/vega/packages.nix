{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    just
    sops
    age
    ssh-to-age
    alejandra
    fh
    nil
    ripgrep
    raycast
    alacritty
    alacritty.terminfo
    element-desktop
    mpv
    obsidian
    orbstack
    slack
    the-unarchiver
    oxfmt
    oxlint
  ];
}
