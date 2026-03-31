{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-web-access";
  version = "0.10.4";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "v0.10.4";
    hash = "sha256-8rxSNJrxk8wPEpnQUuxwvXywkH1e3RecZGYuTRW7wQc=";
  };

  npmDepsHash = "sha256-zau3eaJoa8pE3A5COXwyTLSesoePgYqrnRCg3SMSarw=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Web search, content extraction, and video understanding extension for pi coding agent";
    homepage = "https://github.com/nicobailon/pi-web-access";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
