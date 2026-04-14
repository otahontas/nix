{ pkgs, ... }:
let
  find-and-prune = pkgs.writeShellScriptBin "find-and-prune" (
    builtins.readFile ./scripts/find-and-prune.sh
  );
in
{
  home.packages = [ find-and-prune ];

  programs.fd = {
    enable = true;
    hidden = true;
  };
}
