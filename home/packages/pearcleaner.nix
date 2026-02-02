{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pearcleaner";
  version = "5.4.3";

  src = fetchurl {
    url = "https://github.com/alienator88/Pearcleaner/releases/download/${finalAttrs.version}/Pearcleaner-arm.zip";
    hash = "sha256-9FVOaeEXnPzZCIcwGEI/LX4rWI01Vsvs3Xh4iGbZeqs=";
  };
  dontUnpack = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    unzip -d $out/Applications $src
    rm -rf $out/Applications/__MACOSX

    runHook postInstall
  '';

  meta = {
    description = "Free, source-available Mac app cleaner";
    homepage = "https://github.com/alienator88/Pearcleaner";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
