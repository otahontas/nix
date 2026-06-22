{ pkgs, ... }:

{
  home.packages = [
    pkgs.brewCasks.libreoffice
    (pkgs.writeShellScriptBin "soffice" ''
      app="$HOME/Applications/Home Manager Apps/LibreOffice.app/Contents/MacOS/soffice"
      if [ ! -x "$app" ]; then
        echo "LibreOffice soffice binary not found at $app" >&2
        exit 127
      fi
      exec "$app" "$@"
    '')
  ];
}
