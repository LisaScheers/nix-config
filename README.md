# Nix Darwin Configuration

This repository contains declarative system configurations for macOS (via `nix-darwin`) and NixOS, managed using [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## 📂 Structure

- **`flake.nix`**: Entry point for the configuration. Defines inputs (dependencies) and outputs (system configurations).
- **`hosts/`**: Host-specific configurations.
  - `darwin/`: macOS configurations (e.g., `Lisas-private-MacBook-Pro-3`).
- **`home/`**: Home Manager configurations for users (e.g., `lisa`).
- **`modules/`**: Custom Nix modules (shared configuration blocks).
- **`secrets/`**: Encrypted secrets managed by `sops-nix`.
- **`Justfile`**: Command runner for common tasks.

## 🚀 Getting Started

### Prerequisites

1.  **Install Nix**:

    ```bash
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
    ```

2.  **open nix shell**
    You can enter a development shell with all required tools using:

    ```bash
    nix develop
    ```

### Installation

1.  **Clone the repository**:

    ```bash
    git clone <repo-url> ~/.config/nix-darwin
    cd ~/.config/nix-darwin
    ```

2.  **Enter the Development Shell**:
    This shell provides all necessary tools (`just`, `sops`, `nil`, etc.).

    ```bash
    nix develop
    ```

3.  **Apply Configuration**:
    Use `just` to build and switch to the configuration for the current host.
    ```bash
    just darwin
    ```
    _Or manually:_
    ```bash
    nix run nix-darwin -- switch --flake .
    ```

## 🛠 Usage

The project uses a `Justfile` to simplify common commands. Run `just` to see the list of available commands.

| Command           | Description                             |
| :---------------- | :-------------------------------------- |
| `just darwin`     | Rebuild and switch Darwin configuration |
| `just nixos`      | Rebuild and switch NixOS configuration  |
| `just sops`       | Edit encrypted secrets file             |
| `just fmt`        | Format all Nix files using `alejandra`  |
| `just check`      | Check flake for errors                  |
| `just update`     | Update flake inputs (dependencies)      |
| `just flakehub-status` | Show FlakeHub auth status          |
| `just flakehub-login` | Refresh machine-local FlakeHub auth |
| `just age-keygen` | Generate a new age key for sops         |

## 🔐 Secrets Management

Secrets are managed using [sops-nix](https://github.com/Mic92/sops-nix) with `age` encryption.

1.  **Generate Key**:
    If you are setting this up for the first time on a new machine:

    ```bash
    just age-keygen
    ```

    This will generate a key at `~/.config/sops/age/keys.txt`.

2.  **Edit Secrets**:
    To add or modify secrets:
    ```bash
    just sops
    ```
    This decrypts `secrets/secrets.yaml`, opens it in your editor, and re-encrypts it on save.

## FlakeHub Authentication

This repository already uses FlakeHub-backed inputs, but authentication should stay machine-local and should not be committed into the repo.

On this Mac, Determinate Nix manages FlakeHub authentication through `determinate-nixd`. To inspect or refresh the current login:

```bash
just flakehub-status
just flakehub-login
```

`just flakehub-login` runs `sudo determinate-nixd login`, which refreshes the workstation token used for private flakes and FlakeHub Cache. The `fh` CLI is also installed through the darwin configuration so it is available system-wide after the next rebuild.

## ➕ Adding a New Host

1.  Create a new directory in `hosts/darwin/` or `hosts/nixos/` with your hostname.
2.  Create a `default.nix` in that directory (copy an existing one as a template).
3.  Add the host to `darwinConfigurations` or `nixosConfigurations` in `flake.nix`.
4.  Run `just darwin host="NewHostName"` to build.
