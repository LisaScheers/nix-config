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

## Before installing

The disk layout in `disko-config.nix` reformats `/dev/sda`. Do not run
`nixos-anywhere` against the current server until all of the following
artifacts exist on independent storage and have been restore-tested:

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

After restoration, compare per-mailbox message counts and byte totals on both
sides before changing MX records.

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
address books, sharing ACLs, and ActiveSync.

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
and test local delivery plus authenticated IMAP/SMTP before directing traffic
to the replacement. Keep the old data offline and intact until delayed mail,
webmail, DAV, ActiveSync, aliases, catch-alls, DKIM, SPF, DMARC, and monitoring
have all been verified.

## Intentional differences

- Mailcow's admin UI and API are replaced by the flake configuration.
- Mailcow's quarantine UI, OAuth/TFA UI, and Docker-specific health dashboard
  are not reproduced. Rspamd still classifies spam and the mailserver's Sieve
  integration files spam into Junk.
- Mailcow app passwords are retained for the core mail protocols. SOGo web,
  DAV, and ActiveSync authenticate with the mailbox's primary password because
  native SOGo SQL authentication supports one password hash per account.

## Validation commands

```sh
nix eval --raw path:.#nixosConfigurations.mail.config.system.build.toplevel.drvPath
nix build path:.#nixosConfigurations.mail.config.system.build.toplevel --no-link
```

After boot, use a temporary test message and non-sensitive test credentials to
exercise IMAP, submission, Sieve, webmail, CalDAV/CardDAV, and ActiveSync.
Inspect `systemctl --failed`, the Postfix and Dovecot journals, Rspamd scan
results, SOGo logs, ACME state, and the Alloy endpoint before accepting the
cutover.
