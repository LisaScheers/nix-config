# Nix Darwin And NixOS Configuration

This repository contains declarative macOS and NixOS host configurations managed with Nix flakes.

## Repository Layout

| Path | Purpose | Flake output |
| :--- | :--- | :--- |
| `config.nix` | Checked-in local host, user, and supported-system values | Used by flake modules through `localConfig` |
| `hosts/darwin/Lisas-private-MacBook-Pro/default.nix` | Darwin host entrypoint | `darwinConfigurations.Lisas-private-MacBook-Pro` |
| `hosts/linux/home-server/default.nix` | NixOS host entrypoint | `nixosConfigurations.home-server` |
| `hosts/linux/home-server/disk.nix` | home-server disko layout for nixos-anywhere | Imported by `nixosConfigurations.home-server` |
| `hosts/linux/matrix.bylisa.dev/default.nix` | Matrix NixOS host entrypoint | `nixosConfigurations.matrix.bylisa.dev` |
| `home/lisa/mac-private.nix` | Lisa's macOS Home Manager module | `homeModules.lisa-macos` |
| `modules/darwin/` | Shared nix-darwin modules | Imported by the Darwin host |
| `modules/matrix/` | Shared Matrix service modules | Imported by the Matrix host |
| `modules/authentik/` | Shared Authentik service module | Imported by the Matrix host |
| `modules/forgejo-runner/` | Shared Forgejo runner service module | Imported by the Matrix host |
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
- `matrix.bylisa.dev` on `x86_64-linux`

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

## Distributed Builds

The Darwin host configures Determinate Nix to use `/etc/nix/machines` from a managed block in `/etc/nix/nix.custom.conf`. OrbStack remains available for `aarch64-linux` builds, and `home-server` is configured as an `x86_64-linux` builder through the dedicated `nix-remote-builder` user. The builder SSH private key is stored in `secrets/home-server-builder-ssh-key.json` and installed on the Mac as `/etc/nix/home-server-builder`.

## NixOS Anywhere

The `home-server` host imports the disko module and declares GPT layouts in `hosts/linux/home-server/disk.nix`. The target disks are configured in `config.nix` as `nixosDiskDevices`.

The system target disk is `/dev/disk/by-id/nvme-eui.002538ba71b63d8a`.

The remaining scanned disks are declared as ext4 data disks. They use `noauto,nofail` mount options so a normal rebuild does not mount disks that have not been reformatted yet. Running disko or `nixos-anywhere` with this configuration is destructive for all disks listed here:

| Disk | Device | Mountpoint |
| :--- | :--- | :--- |
| Samsung NVMe 980 500 GB | `/dev/disk/by-id/nvme-eui.002538ba71b63d8a` | `/`, `/boot` |
| Second Life cache NVMe | `/dev/disk/by-id/nvme-eui.00080d02000707ea` | `/srv/disks/second-life-cache-nvme` |
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

## Auto Sync Update

Each declared host runs `services.autoSyncUpdate` every five minutes. The job fast-forwards the local checkout, then switches the matching flake host.

The default checkout path is `/etc/nix-darwin` on NixOS and `config.nix`'s `darwinFlakePath` on macOS. If the checkout does not exist yet, the job can clone it when `AUTO_SYNC_GIT_REPOSITORY_URL` is present.

Credentials are managed with `sops-nix` in `secrets/auto-sync-update.env`. Edit the encrypted file with:

```sh
just sops secrets/auto-sync-update.env
```

The decrypted runtime file is mounted at `/run/secrets/auto-sync-update-env` on each host and should contain:

```sh
AUTO_SYNC_GIT_REPOSITORY_URL=https://github.com/LisaScheers/nix-darwin.git
AUTO_SYNC_GIT_USERNAME=x-access-token
AUTO_SYNC_GIT_TOKEN=replace-me

AUTO_SYNC_SMTP_URL=smtps://smtp.example.com:465
AUTO_SYNC_SMTP_USERNAME=replace-me
AUTO_SYNC_SMTP_PASSWORD=replace-me
AUTO_SYNC_SMTP_FROM=nix-watchdog@scheers.tech
```

`AUTO_SYNC_GIT_AUTH_HEADER` can be used instead of `AUTO_SYNC_GIT_USERNAME` and `AUTO_SYNC_GIT_TOKEN` when the Git server expects an HTTP header. Failures send a watchdog email to `lisa@scheers.tech` once SMTP settings are present.

When a pulled update changes boot artifacts on NixOS, or a reboot marker is present on macOS, the job sends a reboot-required email and schedules a reboot for 12 hours after the update. On NixOS this is a transient `nix-auto-sync-update-reboot` systemd timer; on macOS it uses `shutdown -r +720`.

## Vaultwarden

The `home-server` host runs Vaultwarden at `https://vault.bylisa.dev`. Open signups are disabled; Vaultwarden loads an Argon2-hashed admin token from `secrets/vaultwarden.env`. The plaintext admin token is kept separately in `secrets/vaultwarden-admin-token.env` for login to the admin panel.

Vaultwarden uses SQLite and the NixOS module's built-in `backup-vaultwarden.service` to prepare a consistent local backup under `/srv/disks/western-digital-hdd/vaultwarden/backup`. `restic-backups-vaultwarden.service` then sends that prepared backup over Tailscale SFTP to the `vaultwarden-backup` user on `matrix.bylisa.dev`.

The home server must be joined to the Tailscale network before the remote backup timer can succeed. SMTP placeholders are in `secrets/vaultwarden.env`; edit that SOPS file once the final mail credentials are known.

## Gotify

The `home-server` host runs Gotify at `https://gotify.bylisa.dev`. Registration is disabled, SQLite data lives under the NixOS module state directory, and the initial admin password is loaded from `secrets/gotify.env`.

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
