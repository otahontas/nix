{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lulu";
  version = "4.3.0";

  src = fetchurl {
    url = "https://github.com/objective-see/LuLu/releases/download/v${finalAttrs.version}/LuLu_${finalAttrs.version}.dmg";
    hash = "sha256-8SP5uNEm/fr+FylwQPVDd6rUAspb2EjYCA8zxDaZW/0=";
  };

  dontFixup = true;
  sourceRoot = ".";

  nativeBuildInputs = [ undmg ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R "LuLu.app" "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Open-source firewall to block unknown outgoing connections";
    homepage = "https://objective-see.org/products/lulu.html";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
