{ lib
, stdenv
, autoPatchelfHook
, dpkg
, fetchurl
, graphite2
, makeWrapper
, openssl
, wrapGAppsHook4
, alsa-lib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libdrm
, libglvnd
, libnotify
, libusb1
, libx11
, libxcb
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxkbcommon
, libxrandr
, mesa
, nspr
, nss
, pango
, pipewire
, systemd
, qt5
, qt6Packages
, xdg-utils
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chatgpt";
  version = "26.903.71938";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
    hash = "sha256-E/Rt9zsG324T6edQsvPImphYY3QeqCXS01b1JVn1Wr0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook4
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libglvnd
    libnotify
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    mesa
    nspr
    nss
    pango
    pipewire
    stdenv.cc.cc
    systemd
  ];

  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;

  preFixup = ''
    # Search paths are added directly to autoPatchelfHook, avoiding the
    # incompatible Qt setup hooks while keeping both optional shims usable.
    addAutoPatchelfSearchPath ${qt5.qtbase}/lib
    addAutoPatchelfSearchPath ${qt6Packages.qtbase}/lib
  '';

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a usr/. "$out/"

    # The upstream bundle contains optional musl native modules. This package
    # targets NixOS' glibc userspace, so remove those unused alternatives
    # before autoPatchelfHook checks the remaining ELF files.
    find "$out" -type f -path '*musl*' -delete

    # The Debian package assumes that /usr/share/alsa and /usr/lib/alsa-lib
    # exist. Nix keeps the configuration and the PipeWire backend in the
    # store, so provide both explicitly and make the PipeWire snippets load
    # after the host snippets.
    mkdir -p "$out/share/alsa"
    cp "${alsa-lib}/share/alsa/alsa.conf" "$out/share/alsa/alsa.conf"
    substituteInPlace "$out/share/alsa/alsa.conf" \
      --replace-fail '"/etc/alsa/conf.d"' \
        '"/etc/alsa/conf.d"
				"${pipewire}/share/alsa/alsa.conf.d"'

    # Keep the desktop entry valid: the specification allows one main
    # category, while the upstream entry declares two.
    substituteInPlace "$out/share/applications/chatgpt.desktop" \
      --replace-fail 'Categories=Utility;Development;' 'Categories=Utility;'

    # The bundled Tectonic helper is an ELF with a truncated section-header
    # table, so autoPatchelfHook cannot rewrite it. Run it through Nix's
    # dynamic loader instead and keep the original binary as data behind the
    # wrapper. This supplies its C++, Graphite2 and OpenSSL runtime libraries
    # without disabling or replacing the LaTeX plugin.
    tectonic_dir="$out/lib/chatgpt/resources/plugins/openai-bundled/plugins/latex/bin"
    if test -x "$tectonic_dir/tectonic"; then
      mv "$tectonic_dir/tectonic" "$tectonic_dir/tectonic.real"
      chmod 0444 "$tectonic_dir/tectonic.real"
      makeWrapper "${stdenv.cc.bintools.dynamicLinker}" "$tectonic_dir/tectonic" \
        --add-flags "--library-path ${lib.makeLibraryPath [ stdenv.cc.cc.lib graphite2 openssl ]} $tectonic_dir/tectonic.real"
    fi

    # The Debian launcher is a symlink. Replace it with a Nix wrapper so the
    # desktop entry also gets the runtime tools it expects from PATH.
    rm "$out/bin/chatgpt"
    makeShellWrapper "$out/lib/chatgpt/codex-launcher" "$out/bin/chatgpt" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --set ALSA_CONFIG_PATH "$out/share/alsa/alsa.conf" \
      --set ALSA_CONFIG_DIR "${alsa-lib}/share/alsa" \
      --set ALSA_PLUGIN_DIR "${pipewire}/lib/alsa-lib" \
      --set ELECTRON_OZONE_PLATFORM_HINT wayland \
      --run 'if [ ! -t 1 ] || [ ! -t 2 ]; then log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/chatgpt-nix"; mkdir -p "$log_dir" && exec >>"$log_dir/chatgpt.log" 2>&1 || exec >/dev/null 2>&1; fi' \
      --add-flags "--ozone-platform=wayland"
    runHook postInstall
  '';

  meta = {
    description = "Official ChatGPT desktop application for Linux";
    homepage = "https://developers.openai.com/codex/app";
    license = lib.licenses.unfree;
    mainProgram = "chatgpt";
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
