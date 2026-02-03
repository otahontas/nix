{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
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

  nativeBuildInputs = [ undmg ];

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
