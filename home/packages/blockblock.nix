{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "blockblock";
  version = "2.2.5";

  src = fetchurl {
    url = "https://github.com/objective-see/BlockBlock/releases/download/v${finalAttrs.version}/BlockBlock_${finalAttrs.version}.zip";
    hash = "sha256-g22MTM9LwzvkbwGfHw/LLsYehK+oTbtVCYuw7XNQ/Ik=";
  };

  dontUnpack = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    tmpdir=$(mktemp -d)
    unzip -q "$src" -d "$tmpdir" -x "__MACOSX/*"
    mkdir -p $out/Applications
    cp -R "$tmpdir/BlockBlock Installer.app" "$out/Applications/"
    cp -R "$tmpdir/BlockBlock Installer.app/Contents/Resources/BlockBlock.app" "$out/Applications/"
    cp -R "$tmpdir/BlockBlock Installer.app/Contents/Resources/BlockBlock Helper.app" "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Monitors common persistence locations";
    homepage = "https://objective-see.org/products/blockblock.html";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
