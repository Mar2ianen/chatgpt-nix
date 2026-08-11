{
  description = "Nix package for the official ChatGPT desktop application for Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      package = pkgs.callPackage ./package.nix { };
      app = {
        type = "app";
        program = "${package}/bin/chatgpt";
        meta = {
          description = "Official ChatGPT desktop application for Linux";
          mainProgram = "chatgpt";
        };
      };
    in {
      packages.${system}.default = package;

      apps.${system} = {
        default = app;
        chatgpt = app;
      };

      checks.${system}.package-contract = pkgs.runCommand "chatgpt-package-contract" {
        nativeBuildInputs = [
          pkgs.binutils
          pkgs.desktop-file-utils
          pkgs.file
          pkgs.findutils
          pkgs.gnugrep
        ];
      } ''
        test -x "${package}/bin/chatgpt"
        test -f "${package}/share/applications/chatgpt.desktop"
        test -f "${package}/share/pixmaps/chatgpt.png"
        desktop-file-validate "${package}/share/applications/chatgpt.desktop"
        file "${package}/share/pixmaps/chatgpt.png" | grep -q 'PNG image data'

        wrapper_strings=$(strings "${package}/bin/chatgpt" "${package}/bin/.chatgpt-wrapped")
        ! grep -q -- '--no-sandbox' <<<"$wrapper_strings"
        ! grep -q -- 'ozone-platform=x11' <<<"$wrapper_strings"
        grep -q -- 'ALSA_CONFIG_PATH' <<<"$wrapper_strings"
        grep -q -- 'ALSA_PLUGIN_DIR' <<<"$wrapper_strings"
        grep -q -- 'ozone-platform=wayland' <<<"$wrapper_strings"

        cli="${package}/lib/chatgpt/resources/codex"
        test -x "$cli"
        file "$cli" | grep -q 'static-pie linked'
        "$cli" --version | grep -q '^codex-cli '
        "$cli" --help >/dev/null
        "$cli" app-server --help >/dev/null

        tectonic="${package}/lib/chatgpt/resources/plugins/openai-bundled/plugins/latex/bin/tectonic"
        tectonic_real="$tectonic.real"
        test -x "$tectonic"
        test -f "$tectonic_real"
        test ! -x "$tectonic_real"
        strings "$tectonic" | grep -q 'tectonic.real'

        while IFS= read -r -d "" elf; do
          case "$elf" in
            */tectonic.real) continue ;;
          esac
          if file "$elf" | grep -q 'ELF'; then
            if ldd "$elf" 2>&1 | grep -q 'not found'; then
              echo "unresolved ELF dependency: $elf" >&2
              ldd "$elf" >&2 || true
              exit 1
            fi
          fi
        done < <(find "${package}" -type f -print0)

        touch "$out"
      '';
    };
}
