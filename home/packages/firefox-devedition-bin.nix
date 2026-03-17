{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "firefox-devedition-bin";
  version = "149.0b9";

  src = fetchurl {
    url = "https://archive.mozilla.org/pub/devedition/releases/${finalAttrs.version}/mac/en-US/Firefox%20${finalAttrs.version}.dmg";
    hash = "sha256-uiBVIQ32pUDvYwKNCFrZx3qoRIEzUbNyx7GK2WBM/uw=";
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

    # Disable built-in auto-updater via enterprise policies.
    # Firefox lives in read-only Nix store, so its updater downloads
    # updates it can never apply — causing an endless update loop.
    # Version updates are managed through Nix instead.
    local distDir="$out/Applications/Firefox Developer Edition.app/Contents/Resources/distribution"
    mkdir -p "$distDir"
    cat > "$distDir/policies.json" << 'EOF'
    {
      "policies": {
        "DisableAppUpdate": true,
        "ManualAppUpdateOnly": true
      }
    }
    EOF

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
