{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.2.1";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "v2.2.1";
    hash = "sha256-HTexm+b+UUbJD4qwIqlNcVPhF/G7/MtBtXa0AdeztbY=";
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
