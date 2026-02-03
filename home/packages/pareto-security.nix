{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pareto-security";
  version = "1.21.0";

  src = fetchurl {
    url = "https://github.com/ParetoSecurity/pareto-mac/releases/download/${finalAttrs.version}/ParetoSecurity.dmg";
    hash = "sha256-zG1DnGhg0oiMA2uezU5+/+6T9/PHn293DaLFzT2lANY=";
  };

  dontFixup = true;
  sourceRoot = ".";

  unpackCmd = ''
    echo "Creating temp directory"
    mnt=$(TMPDIR=/tmp mktemp -d -t nix-XXXXXXXXXX)
    function finish {
      echo "Ejecting temp directory"
      /usr/bin/hdiutil detach $mnt -force
      rm -rf $mnt
    }
    trap finish EXIT
    echo "Mounting DMG file into \"$mnt\""
    /usr/bin/hdiutil attach -nobrowse -mountpoint $mnt $curSrc
    echo 'Copying extracted content into "sourceRoot"'
    cp -a "$mnt/Pareto Security.app" $PWD/
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R "Pareto Security.app" "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Security checklist app";
    homepage = "https://paretosecurity.com/";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
