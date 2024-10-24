[group: "update"]
update:
    nix flake update
[group: "rebuild"]
rebuild:
    darwin-rebuild switch --flake .

[group: "install"]
install:
    nix run nix-darwin -- switch --flake .