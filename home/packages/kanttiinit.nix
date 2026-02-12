{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "kanttiinit";
  version = "0.1.0-unstable-2026-02-09";

  src = fetchFromGitHub {
    owner = "otahontas";
    repo = "kanttiinit-cli";
    rev = "b65c4b5ba64b4106f044357379aea3a36ee067e5";
    hash = "sha256-prMoFqLD9+ryAqfj2o2Q4ERJULyX4Vr7m3pDYv8gi98=";
  };

  cargoHash = "sha256-yWpJMX+H+XBuo5G/2HK5hVBL0LZSDl9d1m+zZRsW0Y8=";

  meta = {
    description = "CLI for browsing Helsinki area student restaurant menus from Kanttiinit.fi";
    homepage = "https://github.com/otahontas/kanttiinit-cli";
    license = lib.licenses.mit;
    mainProgram = "kanttiinit";
  };
}
