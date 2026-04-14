{ pkgs, ... }:
let
  listening = pkgs.writeShellScriptBin "listening" (builtins.readFile ./scripts/listening.sh);
  nukeport = pkgs.writeShellScriptBin "nukeport" (builtins.readFile ./scripts/nukeport.sh);
  trash-empty = pkgs.writeShellScriptBin "trash-empty" (builtins.readFile ./scripts/trash-empty.sh);
in
{
  home.packages = [
    listening
    nukeport
    trash-empty
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;
  };
}
