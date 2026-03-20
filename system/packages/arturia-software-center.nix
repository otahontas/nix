{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "arturia-software-center";
  version = "2.12.0.3157";

  src = fetchurl {
    url = "https://dl.arturia.net/products/asc/soft/Arturia_Software_Center__${
      lib.replaceStrings [ "." ] [ "_" ] finalAttrs.version
    }.pkg";
    hash = "sha256-oWTDRcbJFheaP/TAT9M4DdQa0I9ywfw8xv9mAm41hx8=";
  };

  dontUnpack = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    tmpdir=$(mktemp -d)
    /usr/bin/xar -xf "$src" -C "$tmpdir"
    mkdir -p "$out/Applications"
    cd "$tmpdir/Arturia Software Center-2.12.0-Darwin-resources.pkg"
    cat Payload | /usr/bin/gunzip | (cd "$out" && /usr/bin/cpio -id --quiet "./Applications/Arturia/Arturia Software Center.app")
    mv "$out/Applications/Arturia/Arturia Software Center.app" "$out/Applications/"
    rmdir "$out/Applications/Arturia"

    runHook postInstall
  '';

  meta = {
    description = "Installer and manager for Arturia products";
    homepage = "https://www.arturia.com/technology/asc";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
