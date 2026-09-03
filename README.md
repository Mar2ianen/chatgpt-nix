# ChatGPT for Nix

Nix wrapper for the official ChatGPT desktop application distributed as an
amd64 Debian package.

The package is pinned to the DEB currently served by OpenAI:

- version: `26.901.20858`
- source: <https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb>
- SHA-256: `42a6477f22f4136d62321eda7b4697a79da1eb66d61dcb85ab0420860a1a5223`

## Run

Install it into the user profile:

```sh
nix profile install github:Mar2ianen/chatgpt-nix
```

Run it directly without installing a profile:

```sh
nix run github:Mar2ianen/chatgpt-nix
```

The local equivalent is `nix run .#chatgpt` (or simply `nix run .`).
To explicitly accept the flake's public Cachix configuration, add
`--accept-flake-config` to the command.

The flake currently targets `x86_64-linux`, matching the upstream package.
The launcher forces Electron's native Wayland Ozone backend. It intentionally
does not fall back to X11 and does not add any sandbox-disabling flag. ALSA is
wired to the Nix-provided PipeWire backend so microphone capture does not
depend on `/usr/share/alsa` or `/usr/lib/alsa-lib` existing on the host.

## Local checks

```sh
nix flake check
nix build
```

`nix flake check` also validates the desktop entry, icon, wrapper policy,
PipeWire ALSA paths and unresolved ELF dependencies.

## GitHub Actions

The repository builds the package and contract on pushes and manual runs. A
daily worker downloads the latest upstream DEB, calculates both hashes, builds
it first, updates one rolling PR, closes obsolete update PRs, and merges the
validated update automatically.

When an updated package reaches `main`, GitHub Actions creates a matching
release tag and GitHub Release. The release does not redistribute the upstream
DEB; it points users to the flake and `nix run` command. The flake is configured
to use the public `marsianen.cachix.org` cache and its public signing key. The
release worker uses the same cache when `CACHIX_CACHE` is set; add the
`CACHIX_AUTH_TOKEN` secret when it should publish build results to that cache.
The launcher also redirects logs when stdout/stderr are not terminals, which
keeps Electron stable when started from Niri or a desktop entry.

The runtime smoke test should be performed from the graphical session:

```sh
result/bin/chatgpt
```

## Updating

The upstream `latest` URL is intentionally used together with a fixed hash,
so Nix will reject an unexpected package change. When OpenAI publishes a new
build, update `version` and `hash` in `package.nix`, and update the matching
metadata in this README.
