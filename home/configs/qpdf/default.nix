{ pkgs, ... }:
let
  combine-pdfs-in-folder = pkgs.writeShellScriptBin "combine-pdfs-in-folder" (
    builtins.readFile ./scripts/combine-pdfs-in-folder.sh
  );
in
{
  home = {
    packages = [
      pkgs.qpdf
      combine-pdfs-in-folder
    ];
  };
}
