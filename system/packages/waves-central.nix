{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:
stdenvNoCC.mkDerivation (_: {
  pname = "waves-central";
  # pinned at install time; app self-updates
  # refresh hash with: nix-prefetch-url https://cf-installers.waves.com/WavesCentral/Install_Waves_Central.dmg
  version = "16.5.5";

  src = fetchurl {
    url = "https://cf-installers.waves.com/WavesCentral/Install_Waves_Central.dmg";
    hash = "sha256-ULDktkmYhPkZuncx7J4t+0+e+HTL3BKYuJOxo+gfDfU=";
  };

  dontFixup = true;
  sourceRoot = ".";

  nativeBuildInputs = [ undmg ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R "Waves Central.app" "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Client to install and activate Waves products";
    homepage = "https://www.waves.com/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
