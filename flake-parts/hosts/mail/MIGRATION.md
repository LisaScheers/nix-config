# Mailcow to the NixOS mail host

The source of truth for the replacement is the `mail` flake output. The
Mailcow host was audited read-only on 2026-07-14; none of the commands used to
prepare this configuration changed it.

## Included scope

- Domains: `scheers.tech`, `chiritsu.com`, `clovercri.com`, and
  `icetokki.com`.
- Thirteen active mailboxes, their quotas, five aliases, and the two catch-all
  destinations.
- Existing primary password hashes and five active Mailcow app-password hashes.
  App passwords are accepted for IMAP, SMTP, POP3, and ManageSieve according to
  their Mailcow protocol flags.
- The existing `dkim` selector and DKIM private key for each retained domain.
- Postfix, Dovecot, Rspamd, Redis, ClamAV, full-text search, SRS, DMARC reports,
  TLS reports, Fail2ban, ACME, SOGo, CalDAV/CardDAV, ActiveSync, Thunderbird
  autoconfiguration, Cloudflare Tunnel, and Alloy monitoring.
- Lisa's all-sender permission and the `info@clovercri.com` domain-sender
  permission.

The following domains are deliberately omitted: `collabkins.com`,
`meltibelti.com`, `drone-8653.com`, `miraa.dev`, and
`ngpoolservice.be`.

## Pre-deployment validation gates

Run every gate below from the repository before any destructive installation.
Do not continue unless every command exits successfully:

```sh
set -eu

nix eval --raw path:.#nixosConfigurations.mail.config.system.build.toplevel.drvPath
nix build path:.#checks.x86_64-linux.mail --no-link

identity="$HOME/.config/sops/age/keys.txt"
for secret in flake-parts/agenix/secrets/mail/*.age; do
  age -d -i "$identity" "$secret" >/dev/null
done

for key in flake-parts/agenix/secrets/mail/dkim-*.age; do
  age -d -i "$identity" "$key" |
    openssl rsa -check -noout >/dev/null 2>&1
done

system=$(nix build path:.#nixosConfigurations.mail.config.system.build.toplevel --no-link --print-out-paths)
lua_file=$(readlink -f "$system/etc/dovecot/app-passwords.lua")
nix shell nixpkgs#lua -c luac -p "$lua_file"

git diff --check
```

These gates validate evaluation, the complete mail-host check build, all age
recipients, all retained DKIM private keys, the generated Dovecot app-password
Lua, and whitespace integrity. Record the successful output with the cutover
notes.

## Before installing

The disk layout in `disko-config.nix` reformats the disk identified as
`/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_100270732` (currently
`/dev/sda`). Do not run `nixos-anywhere` against the current server until
all of the following artifacts exist on independent storage and have been
restore-tested:

1. A filesystem-level copy of the Mailcow vmail volume.
2. A MariaDB dump of every `sogo_%` table used by Mailcow.
3. The current SSH host identity:
   `/etc/ssh/ssh_host_ed25519_key` and its `.pub` file.
4. A final incremental vmail copy and SOGo dump taken while inbound delivery,
   Dovecot, and SOGo are stopped.

The current VM was verified to boot in legacy BIOS mode. GRUB is therefore
installed to `/dev/sda`, using the GPT BIOS boot partition declared by Disko.

The encrypted age files currently include the existing server SSH host public
key as a recipient. Restore that same private host key during installation, or
add the new host public key to `flake-parts/agenix/pubkeys.nix` and run
`just secret-rekey` before first boot. Never commit a private SSH key.

## Mail data

Mailcow stores the source Maildirs below:

```
/var/lib/docker/volumes/mailcowdockerized_vmail-vol-1/_data/<domain>/<user>/Maildir
```

The NixOS mailserver stores mail below `/var/vmail/<domain>/<user>`. Copy the
contents of each source `Maildir` into the corresponding destination mailbox,
preserving timestamps and hard links. On the destination, make the resulting
tree owned by `virtualMail:virtualMail` (numeric UID/GID 5000 in this
configuration). Stop Dovecot during the final copy, then remove or rebuild the
Dovecot indexes before starting it.

For every mailbox, generate a deterministic manifest of the message files under
all `cur` and `new` directories on the frozen source and restored
destination. Use relative filenames and SHA-256 content hashes, for example:

```sh
cd /path/to/mailbox
find . -type f \( -path '*/cur/*' -o -path '*/new/*' \) -print0 |
  sort -z |
  xargs -0 sha256sum --binary --zero > /independent-storage/mailbox.manifest
```

Generate the source and destination manifests separately, then compare them
with `cmp`. Also run an `rsync --archive --hard-links --checksum --dry-run`
against each mailbox and compare message counts and byte totals. Counts and
totals are supplementary checks only: any filename, checksum, manifest, or
rsync content delta is a cutover blocker and must be reconciled before changing
MX records.

## SOGo data

Let the new host boot once so MariaDB and the declarative `accounts` table are
created. Stop SOGo, then restore the Mailcow SOGo data tables into the new
`sogo` database. Preserve at least:

- `sogo_acl`
- `sogo_admin`
- `sogo_alarms_folder`
- `sogo_cache_folder`
- `sogo_folder_info`
- `sogo_quick_appointment`
- `sogo_quick_contact`
- `sogo_sessions_folder`
- `sogo_store`
- `sogo_user_profile`

Do not replace the new `accounts` table: it is regenerated from
`accounts.nix` on every boot. Restore any additional Mailcow `sogo_%` data
tables that appear in the final dump, then start SOGo and verify calendars,
address books, sharing ACLs, and ActiveSync. Record source and destination row
counts for every restored table and compare normalized dumps or table checksums;
any unexplained data-table delta blocks cutover.

## DNS and cutover checks

The existing MX, A/AAAA, PTR, and DKIM selector can remain unchanged if this
configuration replaces Mailcow on the same addresses. Before cutover, verify:

- `m.scheers.tech` resolves to `188.245.70.181` and
  `2a01:4f8:1c1e:ba3a::1`.
- The IPv4 PTR is `m.scheers.tech`.
- Every retained domain has MX `m.scheers.tech` and the published
  `dkim._domainkey` value matches the retained private key.
- TCP 25 is reachable directly; the Cloudflare proxy is only for the web
  endpoint.
- ACME can reach port 80 for `m.scheers.tech`.

The audit found two existing DNS issues that are not changed by this flake:
`chiritsu.com` publishes two SPF TXT records, which is invalid, and
`icetokki.com` has no DMARC record. None of the retained domains currently
publishes TLS-RPT or MTA-STS DNS records. Correct these separately from the
server cutover.

Lower MX TTLs before the maintenance window. During the window, freeze the old
server, take the final incremental backups, restore, start the NixOS services,
and complete the credential matrix below before directing traffic to the
replacement. Keep the old data offline and intact until delayed mail, webmail,
DAV, ActiveSync, aliases, catch-alls, DKIM, SPF, DMARC, and monitoring have all
been verified.

## Credential and protocol matrix

Use non-sensitive test accounts and temporary credentials. Do not print or
record passwords in shell history or logs. For every one of the five migrated
app passwords, compare each Mailcow protocol flag with the observed result:
enabled protocols must authenticate and disabled protocols must reject it.

| Path | Endpoint | Positive test | Negative test |
| --- | --- | --- | --- |
| IMAP | `m.scheers.tech:993` TLS | Enabled app password and primary password authenticate and can list folders. | Disabled app password and an incorrect password are rejected. |
| SMTP submission | `m.scheers.tech:465` TLS and `:587` STARTTLS | Enabled app password and primary password authenticate and deliver a test message. | Disabled app password, wrong password, and unauthorized sender address are rejected. |
| POP3 | `m.scheers.tech:995` TLS and `:110` STARTTLS | Enabled app password and primary password authenticate and list a disposable test message. | Disabled app password and an incorrect password are rejected. |
| ManageSieve | `m.scheers.tech:4190` STARTTLS | Enabled app password and primary password authenticate and round-trip a temporary script. | Disabled app password and an incorrect password are rejected. |
| SOGo webmail | `https://mail.scheers.tech/SOGo/` | Primary password signs in and opens the mailbox. | Every app password and an incorrect primary password are rejected. |
| CalDAV/CardDAV | SOGo DAV URLs | Primary password can read and write a temporary event and contact. | Every app password and an incorrect primary password are rejected. |
| ActiveSync | `/Microsoft-Server-ActiveSync` | Primary password completes provisioning and a test sync. | Every app password and an incorrect primary password are rejected. |

Repeat SMTP receive and delivery tests for every retained domain, alias, and
catch-all. Verify the message arrives once with the expected envelope recipient,
then verify outbound DKIM and DMARC results from an external mailbox.

## Rollback gate and procedure

Because installation reformats the current Mailcow disk, backups alone are not
a fast rollback. Before installation, create a bootable provider snapshot or
clone of the complete Mailcow server and prove that it boots with networking
disabled or on an isolated address. Record the previous DNS values and TTLs.

Trigger rollback if any of these conditions is true:

- Any Maildir or SOGo manifest, checksum, filename, or row-count discrepancy
  remains.
- Any required positive credential test fails twice, or any required negative
  test unexpectedly succeeds.
- Inbound or outbound SMTP is unavailable, or the deferred Postfix queue grows
  because of a local failure for more than 15 minutes.
- DKIM, SPF, DMARC, TLS certificate, aliases, or catch-all verification fails.
- A critical service remains failed after a 30-minute troubleshooting window.

When a trigger fires:

1. Stop public ingress and freeze Postfix, Dovecot, SOGo, and the Cloudflare
   tunnel on the replacement. Preserve `/var/spool/postfix`; do not discard or
   bounce queued mail.
2. Copy the replacement's complete `/var/vmail` tree and a fresh SOGo database
   dump to independent rollback storage. Create manifests so post-cutover mail
   and groupware changes can be identified.
3. Restore or boot the verified Mailcow snapshot/clone. Restore the recorded
   A/AAAA, MX, and tunnel routing if addresses changed, then verify the old
   server locally before reopening SMTP.
4. Reconcile messages received only by the replacement using relative paths,
   content hashes, and Message-IDs. Import each missing message exactly once.
   Reconcile SOGo changes from the rollback dump without replacing newer
   records blindly.
5. Drain or replay the preserved Postfix queue under operator supervision,
   verify it is empty, repeat the delivery and credential matrices, and only
   then declare Mailcow active again.

External senders should receive temporary failures and retry while both hosts
are frozen. Never run both hosts as writable authorities for the same mailbox
during rollback reconciliation.

## Intentional differences

- Mailcow's admin UI and API are replaced by the flake configuration.
- Mailcow's quarantine UI, OAuth/TFA UI, and Docker-specific health dashboard
  are not reproduced. Rspamd still classifies spam and the mailserver's Sieve
  integration files spam into Junk.
- Mailcow app passwords are retained for the core mail protocols. SOGo web,
  DAV, and ActiveSync authenticate with the mailbox's primary password because
  native SOGo SQL authentication supports one password hash per account.

After boot, use a temporary test message and non-sensitive test credentials to
complete the full credential and protocol matrix. Inspect
`systemctl --failed`, the Postfix and Dovecot journals, Rspamd scan results,
SOGo logs, ACME state, and the Alloy endpoint before accepting the cutover.
