# Nix Darwin And NixOS Configuration

This repository contains declarative macOS and NixOS host configurations managed with Nix flakes.

## Repository Layout

| Path | Purpose | Flake output |
| :--- | :--- | :--- |
| `config.nix` | Checked-in local host, user, and supported-system values | Used by flake modules through `localConfig` |
| `hosts/darwin/Lisas-private-MacBook-Pro/default.nix` | Darwin host entrypoint | `darwinConfigurations.Lisas-private-MacBook-Pro` |
| `hosts/linux/home-server/default.nix` | NixOS host entrypoint | `nixosConfigurations.home-server` |
| `home/lisa/mac-private.nix` | Lisa's macOS Home Manager module | `homeModules.lisa-macos` |
| `modules/darwin/` | Shared nix-darwin modules | Imported by the Darwin host |
| `apps/` | Thin workflow scripts for `nix run` apps | `apps.${system}.*` |
| `secrets/secrets.yaml` | SOPS-encrypted secret data | Consumed by `sops-nix` at activation |

There are no template outputs because this is a private configuration repository, not a starter flake.

## Supported Systems

`config.nix` defines the per-system flake outputs for:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

Host configurations are currently declared for:

- `Lisas-private-MacBook-Pro` on `aarch64-darwin`
- `home-server` on `x86_64-linux`

CI runs `nix flake check` on the native GitHub Linux runner. `nix flake check --all-systems` requires matching Darwin and aarch64 builders, so run it locally only when those builders are available.

## Development

Enter the development shell:

```sh
nix develop
```

Format Nix files:

```sh
nix fmt
nix fmt -- --check
```

Validate the flake:

```sh
nix flake check
nix flake show
nix flake metadata
```

Build host configurations directly:

```sh
nix build .#darwinConfigurations.Lisas-private-MacBook-Pro.system
nix build .#nixosConfigurations.home-server.config.system.build.toplevel
```

## Workflow Apps

The flake exposes thin `nix run` wrappers around checked-in scripts under `apps/`.

| Command | Description |
| :--- | :--- |
| `nix run .#build` | Build the host configuration for the current supported system |
| `nix run .#build-switch` | Build and switch the host configuration for the current supported system |
| `nix run .#apply` | Alias for `build-switch` |
| `nix run .#update` | Run `nix flake update` |
| `nix run .#clean` | Run `nix-collect-garbage --delete-older-than 14d` |

`build-switch`, `apply`, `update`, and `clean` have side effects. The scripts print the target host or system before running.

## Just Commands

The `Justfile` keeps common commands short:

| Command | Description |
| :--- | :--- |
| `just fmt` | Format all Nix files |
| `just fmt-check` | Check formatting |
| `just check` | Run `nix flake check` |
| `just check-all` | Run `nix flake check --all-systems` when builders are available |
| `just build` | Run `nix run .#build` |
| `just apply` | Run `nix run .#build-switch` |
| `just darwin` | Rebuild and switch the Darwin configuration |
| `just nixos` | Rebuild and switch the NixOS configuration |
| `just update` | Update flake inputs |
| `just sops` | Edit the encrypted secrets file |
| `just age-keygen` | Generate a local age key for SOPS |

## Secrets

Secrets are managed with `sops-nix` and age. The checked-in `secrets/secrets.yaml` file is encrypted; decrypted material and age private keys must stay outside the Nix store and outside Git.

Bootstrap a local age key:

```sh
just age-keygen
```

Edit encrypted secrets:

```sh
just sops
```

The age private key path is configured in `config.nix` as `sopsAgeKeyFile`. Do not put private keys, tokens, or decrypted secret files in `flake.nix`, shell hooks, derivation arguments, or tracked source files.

## FlakeHub Authentication

FlakeHub authentication is machine-local and must not be committed. On this Mac, Determinate Nix manages authentication through `determinate-nixd`:

```sh
just flakehub-status
just flakehub-login
```

## Adding A Host

1. Create a new host directory under `hosts/darwin/` or `hosts/linux/`.
2. Add a `default.nix` entrypoint for the host.
3. Add the host output in `flake.nix`.
4. Add shared host or user values to `config.nix` when they should be visible to modules.
5. Document the new path-to-output mapping in this README.
