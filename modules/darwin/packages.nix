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
    gemini-cli
    raycast
    alacritty
    audacity
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
