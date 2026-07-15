# forge

## About

### Ephemeral remote shell

Use `nssh host` to enter the secret-free Nushell profile over SSH. Ordinary
`ssh` remains unchanged. Agent forwarding is disabled unless `nssh -A host` is
used explicitly. With `-A`, the host receives only the SSH-agent interface
(including a locally configured 1Password SSH agent), so it can request
signatures while the session is open but never receives private keys or `op`
secret values.

Linux sessions use the bundled nix-portable/PRoot runtime and temporary store.
Darwin sessions require Nix to be installed already; their session files are
removed on exit, while fetched store paths remain garbage-collectable.

From a local or console session, including Atlas, use:

```sh
curl -fsSL https://shell.bylisa.dev | sh
```

The shorter `curl -s https://shell.bylisa.dev | sh` form also works, but
`-fsSL` reports HTTP failures instead of passing an error response to `sh`.

## References

1. This project was built using [tsandrini/flake-parts-builder](https://github.com/tsandrini/flake-parts-builder/)
