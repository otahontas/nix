{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "v2.4.0";
    hash = "sha256-41f4kS6At7GQIfStEeQPRIQaFN5oMs6SrgDsNTeHhLE=";
  };

  npmDepsHash = "sha256-9P71EDq++Bmez3QDEbOL+PCtCFI2ajxy345stBOBp8k=";

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
