{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (_: {
  pname = "native-access";
  # pinned at install time; app self-updates
  # refresh hash with: nix-prefetch-url https://na-update.native-instruments.com/arm64/Native-Access-arm64-mac-latest.zip
  version = "3.23.0";

  src = fetchurl {
    url = "https://na-update.native-instruments.com/arm64/Native-Access-arm64-mac-latest.zip";
    hash = "sha256-zmsNMNUOu+/qs1ON2jaxOTwrxty3KeYmFULxTS4fNtc=";
  };

  dontUnpack = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    tmpdir=$(mktemp -d)
    unzip -q "$src" -d "$tmpdir"
    mkdir -p "$out/Applications"
    cp -R "$tmpdir/Native Access.app" "$out/Applications/"

    runHook postInstall
  '';

  meta = {
    description = "Administration tool for Native Instruments products";
    homepage = "https://www.native-instruments.com/en/specials/native-access/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
  };
})
