{ lib
, stdenv
, autoPatchelfHook
, dpkg
, fetchurl
, makeWrapper
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
, systemd
, qt5
, qt6Packages
, xdg-utils
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chatgpt";
  version = "26.803.81509";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
    hash = "sha256-qb+Ro2j598Tuo4CCqfuPtGuNAFtxmm13FdLloZgsOOs=";
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

    # The Debian launcher is a symlink. Replace it with a Nix wrapper so the
    # desktop entry also gets the runtime tools it expects from PATH.
    rm "$out/bin/chatgpt"
    makeWrapper "$out/lib/chatgpt/codex-launcher" "$out/bin/chatgpt" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --set ELECTRON_OZONE_PLATFORM_HINT wayland \
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
