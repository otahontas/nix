{ pkgs, ... }:
let
  utils = builtins.readFile ./scripts/utils.sh;
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "listening" utils)
    (pkgs.writeShellScriptBin "nukeport" utils)
    (pkgs.writeShellScriptBin "trash-empty" utils)
  ];
}
