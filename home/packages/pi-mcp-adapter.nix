{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "v2.2.0";
    hash = "sha256-E6Kf+OyTN/pF8pKADJO0B1+buAPqNcXnZl9ssZwSP8U=";
  };

  npmDepsHash = "sha256-myJ9h/zC/KDddt8NOVvJjjqbnkdEN4ZR+okCR5nu7hM=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "MCP adapter extension for pi coding agent";
    homepage = "https://github.com/nicobailon/pi-mcp-adapter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
