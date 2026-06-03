# Nix Darwin And NixOS Configuration

This repository contains declarative macOS and NixOS host configurations managed with Nix flakes.

## Repository Layout

| Path | Purpose | Flake output |
| :--- | :--- | :--- |
| `config.nix` | Checked-in local host, user, and supported-system values | Used by flake modules through `localConfig` |
| `hosts/darwin/Lisas-private-MacBook-Pro/default.nix` | Darwin host entrypoint | `darwinConfigurations.Lisas-private-MacBook-Pro` |
| `hosts/linux/home-server/default.nix` | NixOS host entrypoint | `nixosConfigurations.home-server` |
| `hosts/linux/home-server/disk.nix` | home-server disko layout for nixos-anywhere | Imported by `nixosConfigurations.home-server` |
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

`x86_64-darwin` is kept as transitional Intel Mac support. Nixpkgs 26.05 warns that it is the last release supporting that platform, so remove it from `config.nix` when Intel Mac outputs are no longer needed.

CI evaluates every declared supported system with `nix flake check --all-systems --no-build`, then runs `nix flake check` on the native GitHub Linux runner. Full `nix flake check --all-systems` builds require matching Darwin and aarch64 builders, so run it only where those builders are available.

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
| `nix run .#build` | Build the host configuration for the current system when a host is declared |
| `nix run .#build-switch` | Build and switch the host configuration for the current system when a host is declared |
| `nix run .#apply` | Alias for `build-switch` |
| `nix run .#update` | Run `nix flake update` |
| `nix run .#clean` | Run `nix-collect-garbage --delete-older-than 14d` |

`build`, `build-switch`, and `apply` are exposed only for systems with declared host outputs. `build-switch`, `apply`, `update`, and `clean` have side effects. The scripts print the target host or system before running.

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
| `just nixos-install root@<ip-or-host>` | Install `home-server` with nixos-anywhere and generated hardware config |
| `SSHPASS=... just nixos-install-password root@<ip-or-host>` | Install with nixos-anywhere using password auth |
| `just nixos-install-from-installer root@<ip-or-host>` | Install from an already booted NixOS installer, skipping kexec |
| `SSHPASS=... just nixos-install-from-installer-password root@<ip-or-host>` | Install from an already booted NixOS installer using password auth |
| `just nixos-install-from-installer-key root@<ip-or-host> /tmp/home-server-installer-ed25519` | Install from an already booted NixOS installer using a specific SSH key |
| `just update` | Update flake inputs |
| `just sops` | Edit the encrypted secrets file |
| `just age-keygen` | Generate a local age key for SOPS |

## NixOS Anywhere

The `home-server` host imports the disko module and declares GPT layouts in `hosts/linux/home-server/disk.nix`. The target disks are configured in `config.nix` as `nixosDiskDevices`.

The system target disk is `/dev/disk/by-id/nvme-eui.002538ba71b63d8a`.

The remaining scanned disks are declared as ext4 data disks. They use `noauto,nofail` mount options so a normal rebuild does not mount disks that have not been reformatted yet. Running disko or `nixos-anywhere` with this configuration is destructive for all disks listed here:

| Disk | Device | Mountpoint |
| :--- | :--- | :--- |
| Samsung NVMe 980 500 GB | `/dev/disk/by-id/nvme-eui.002538ba71b63d8a` | `/`, `/boot` |
| Former XCP-ng NVMe | `/dev/disk/by-id/nvme-eui.00080d02000707ea` | `/srv/disks/xcp-ng-nvme` |
| Kingston SATA SSD 240 GB | `/dev/disk/by-id/ata-KINGSTON_SUV400S37240G_50026B726406FC2C` | `/srv/disks/kingston-ssd` |
| WDC SATA HDD 2 TB | `/dev/disk/by-id/wwn-0x50014ee261c9005d` | `/srv/disks/western-digital-hdd` |

Networking is configured with systemd-networkd on the untagged physical NIC `enp7s0`. The interface uses static IPv4 `192.168.111.2/24`, gateway `192.168.111.1`, DNS `192.168.111.1`, and IPv6 SLAAC via router advertisements.

Install onto a reachable Linux target:

```sh
just nixos-install root@<ip-or-host>
```

This runs `nixos-anywhere`, kexecs into the NixOS installer, generates `hosts/linux/home-server/hardware-configuration.nix`, partitions/formats the configured disks, installs `nixosConfigurations.home-server`, and reboots the target. This is destructive for every disk declared in `hosts/linux/home-server/disk.nix`.

XCP-ng's dom0 kernel may fail the kexec phase with `Could not get memory layout`. In that case, boot the machine into a NixOS installer ISO manually, configure SSH/networking in the installer, and run:

```sh
just nixos-install-from-installer root@<ip-or-host>
```

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
