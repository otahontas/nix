{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "macwhisper";
  version = "13.12.2";
  build = "1376";

  src = fetchurl {
    url = "https://cdn.macwhisper.com/macwhisper/MacWhisper-${finalAttrs.build}.zip";
    hash = "sha256-nC8LvB4or5vND1OypmOO/u8ljFXFZoAmuSnF9kZ2zjg=";
  };

  dontUnpack = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    unzip -q -d $out/Applications $src -x "__MACOSX/*"

    runHook postInstall
  '';

  meta = {
    description = "Speech recognition tool";
    homepage = "https://goodsnooze.gumroad.com/l/macwhisper";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
