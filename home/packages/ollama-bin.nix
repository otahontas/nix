{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ollama-bin";
  version = "0.17.1";

  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${finalAttrs.version}/ollama-darwin.tgz";
    hash = "sha256-2A/fpWW4F1ZATJZhLsb1bX1BdzYPu9lymCD2m8osc9s=";
  };

  dontUnpack = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/ollama

    runHook postInstall
  '';

  meta = {
    description = "Get up and running with large language models locally (upstream prebuilt binary)";
    homepage = "https://github.com/ollama/ollama";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "ollama";
  };
})
