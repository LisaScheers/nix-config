# Justfile for nix-config automation
matrix-server := env_var_or_default("MATRIX_HOST", "lisa@100.87.26.75")
matrix-flake := "matrix.bylisa.dev"
matrix-ssh := "ssh -o IdentitiesOnly=yes -o IdentityFile=~/.ssh/hetzner-mc"

# Default recipe - show available commands
default:
    @just --list

# Format all Nix files using alejandra
fmt:
    nix fmt

# Rebuild Darwin configuration
darwin host="Lisas-private-MacBook-Pro":
    sudo darwin-rebuild switch --flake .#"{{host}}"

# Rebuild NixOS configuration
nixos host="home-server":
    nixos-rebuild switch --flake .#"{{host}}"

# Install the home server with nixos-anywhere.
# WARNING: this repartitions and formats the disk configured in config.nix.
nixos-install target host="home-server":
    nix develop --command nixos-anywhere --generate-hardware-config nixos-generate-config ./modules/hosts/"{{host}}"/_hardware-configuration.nix --flake .#"{{host}}" --target-host "{{target}}"

# Install using password auth. Set SSHPASS in the environment before running this.
# WARNING: this repartitions and formats the disk configured in config.nix.
nixos-install-password target host="home-server":
    nix develop --command nixos-anywhere --env-password --generate-hardware-config nixos-generate-config ./modules/hosts/"{{host}}"/_hardware-configuration.nix --flake .#"{{host}}" --target-host "{{target}}"

# Install from an already-booted NixOS installer environment, skipping kexec.
# WARNING: this repartitions and formats the disks configured in config.nix.
nixos-install-from-installer target host="home-server":
    nix develop --command nixos-anywhere --phases disko,install,reboot --generate-hardware-config nixos-generate-config ./modules/hosts/"{{host}}"/_hardware-configuration.nix --flake .#"{{host}}" --target-host "{{target}}"

# Install from an already-booted NixOS installer environment with password auth.
# WARNING: this repartitions and formats the disks configured in config.nix.
nixos-install-from-installer-password target host="home-server":
    nix develop --command nixos-anywhere --env-password --phases disko,install,reboot --generate-hardware-config nixos-generate-config ./modules/hosts/"{{host}}"/_hardware-configuration.nix --flake .#"{{host}}" --target-host "{{target}}"

# Install from an already-booted NixOS installer environment with a specific SSH key.
# WARNING: this repartitions and formats the disks configured in config.nix.
nixos-install-from-installer-key target identity="/tmp/home-server-installer-ed25519" host="home-server":
    nix develop --command nixos-anywhere -i "{{identity}}" --phases disko,install,reboot --generate-hardware-config nixos-generate-config ./modules/hosts/"{{host}}"/_hardware-configuration.nix --flake .#"{{host}}" --target-host "{{target}}"

# Edit or create an agenix secret. Paths are relative to flake-parts/agenix.
secret-edit file identity="/Users/lisa/.config/sops/age/keys.txt":
    cd flake-parts/agenix && RULES=./secrets.nix agenix --edit "{{file}}" --identity "{{identity}}"

# Re-encrypt all agenix secrets after changing recipients in secrets.nix.
secret-rekey identity="/Users/lisa/.config/sops/age/keys.txt":
    cd flake-parts/agenix && RULES=./secrets.nix agenix --rekey --identity "{{identity}}"

# Check flake
check:
    nix flake check

# Check flake on every declared supported system when matching builders are available
check-all:
    nix flake check --all-systems

# Check formatting without modifying files
fmt-check:
    nix fmt -- --check

# Update flake inputs
update:
    nix flake update

# Regenerate flake.nix from flake-file declarations
write-flake:
    nix run .#write-flake

# Show flake tree
tree:
    nix flake show

# Enter development shell
dev:
    nix develop

# Build the host configuration for the current supported system
build:
    nix run .#build

# Build and switch the host configuration for the current supported system
apply:
    nix run .#build-switch

# Deploy the current working tree to the home-server and switch it.
# Uses normal SSH auth, or password auth when SSHPASS is set.
deploy-home-server:
    nix run .#deploy-home-server

# Sync the current working tree to the Matrix server.
matrix-sync:
    rsync -a -e '{{matrix-ssh}}' --exclude=.direnv . {{matrix-server}}:~/flake

# Deploy the current working tree to the Matrix server and switch it.
matrix-switch:
    just matrix-sync
    {{matrix-ssh}} {{matrix-server}} -t "sudo nixos-rebuild switch --flake ~/flake#{{matrix-flake}}"

# Test the Matrix server configuration remotely.
matrix-check:
    just matrix-sync
    {{matrix-ssh}} {{matrix-server}} -t "sudo nixos-rebuild test --flake ~/flake#{{matrix-flake}}"

# Build Darwin configuration (dry-run)
darwin-build host="Lisas-private-MacBook-Pro":
    darwin-rebuild build --flake .#"{{host}}"

# Build NixOS configuration (dry-run)
nixos-build host="home-server":
    nixos-rebuild build --flake .#"{{host}}"

# Generate an age identity for agenix (if needed).
age-keygen:
    @echo "Generating age identity for agenix..."
    @mkdir -p ~/.config/sops/age
    @age-keygen -o ~/.config/sops/age/keys.txt
    @echo "Age key generated at ~/.config/sops/age/keys.txt"
    @echo "Add the public key to flake-parts/agenix/pubkeys.nix and the relevant rules in flake-parts/agenix/secrets.nix"
