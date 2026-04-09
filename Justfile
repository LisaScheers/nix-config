# Justfile for nix-config automation

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

# Initialize secrets file with sops (run once before first use)
sops-init file="secrets/secrets.yaml":
    @echo "Initializing encrypted secrets file..."
    @if [ ! -f "{{file}}" ] || [ ! -s "{{file}}" ]; then \
        echo "{}" > "{{file}}"; \
    fi
    @sops --config .sops.yaml --encrypt --in-place "{{file}}"
    @echo "Secrets file initialized. You can now edit it with: just sops"

# Edit secrets using sops (auto-initializes if needed)
sops file="secrets/secrets.yaml":
    # Check if file is encrypted by trying to decrypt it
    @if ! sops --config .sops.yaml --decrypt "{{file}}" > /dev/null 2>&1; then \
        echo "File not encrypted yet. Initializing..."; \
        if [ ! -f "{{file}}" ] || [ ! -s "{{file}}" ]; then \
            echo "{}" > "{{file}}"; \
        fi; \
        sops --config .sops.yaml --encrypt --in-place "{{file}}"; \
        echo "File initialized."; \
    fi
    sops --config .sops.yaml edit "{{file}}"

# Check flake
check:
    nix flake check

# Update flake inputs
update:
    nix flake update

# Show flake tree
tree:
    nix flake show

# Enter development shell
dev:
    nix develop

# Check whether the current machine is authenticated to FlakeHub Cache
flakehub-status:
    determinate-nixd status

# Refresh machine-local FlakeHub authentication
flakehub-login:
    sudo determinate-nixd login

# Build Darwin configuration (dry-run)
darwin-build host="Lisas-private-MacBook-Pro":
    darwin-rebuild build --flake .#"{{host}}"

# Build NixOS configuration (dry-run)
nixos-build host="home-server":
    nixos-rebuild build --flake .#"{{host}}"

# Generate age key for sops (if needed)
age-keygen:
    @echo "Generating age key for sops..."
    @mkdir -p ~/.config/sops/age
    @age-keygen -o ~/.config/sops/age/keys.txt
    @echo "Age key generated at ~/.config/sops/age/keys.txt"
    @echo "Add the public key to .sops.yaml"
