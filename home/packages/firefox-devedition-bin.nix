{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "firefox-devedition-bin";
  version = "148.0b10";

  src = fetchurl {
    url = "https://archive.mozilla.org/pub/devedition/releases/${finalAttrs.version}/mac/en-US/Firefox%20${finalAttrs.version}.dmg";
    hash = "sha256-xnMNEG0UNIJOC2Kx3XGm6WJ2ibdiMuLZAFgCv+M1Y0M=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ undmg ];

  # Keep app signature as-is.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"

    if [ -d "Firefox Developer Edition.app" ]; then
      mv "Firefox Developer Edition.app" "$out/Applications/"
    elif [ -d "Firefox.app" ]; then
      mv "Firefox.app" "$out/Applications/Firefox Developer Edition.app"
    else
      echo "Could not find Firefox app in DMG contents"
      ls -la
      exit 1
    fi

    runHook postInstall
  '';

  meta = {
    description = "Mozilla Firefox Developer Edition (binary package)";
    homepage = "https://www.mozilla.org/firefox/developer/";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "firefox";
  };
})
