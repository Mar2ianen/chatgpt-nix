# ChatGPT for Nix

Nix wrapper for the official ChatGPT desktop application distributed as an
amd64 Debian package.

The package is pinned to the DEB currently served by OpenAI:

- version: `26.803.81509`
- source: <https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb>
- SHA-256: `a9bf91a368f9f7c4eea38082a9fb8fb46b8d005b719a6d7715d2e5a1982c38eb`

## Run

```sh
nix run github:Mar2ianen/chatgpt-nix
```

Install it into the user profile:

```sh
nix profile install github:Mar2ianen/chatgpt-nix
```

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

The runtime smoke test should be performed from the graphical session:

```sh
result/bin/chatgpt
```

## Updating

The upstream `latest` URL is intentionally used together with a fixed hash,
so Nix will reject an unexpected package change. When OpenAI publishes a new
build, update `version` and `hash` in `package.nix`, and update the matching
metadata in this README.
