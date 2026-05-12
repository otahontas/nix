{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "pi-subagents";
  version = "0.24.2";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "v0.24.2";
    hash = "sha256-yBWgnZYw4OjSxKOmiQOltdM/jSbnHa/tdOBwUgNDkXU=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    runHook postInstall
  '';

  meta = {
    description = "Subagent delegation extension for pi coding agent";
    homepage = "https://github.com/nicobailon/pi-subagents";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
