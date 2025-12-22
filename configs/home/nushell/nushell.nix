{
  lib,
  pkgs,
  ...
}:
let
  configsDir = ../.;
  toolDirs = builtins.readDir configsDir;
  collectNuFiles = lib.attrsets.mapAttrsToList (
    name: type:
    let
      nuFile = configsDir + "/${name}/${name}.nu";
    in
    if type == "directory" && name != "nushell" && builtins.pathExists nuFile then
      builtins.readFile nuFile
    else
      ""
  ) toolDirs;
  allIntegrations = lib.concatStrings collectNuFiles;
  coreConfig = builtins.readFile ./nushell.nu;
in
{
  catppuccin.nushell.enable = true;
  programs.nushell = {
    enable = true;
    extraConfig = coreConfig + "\n" + allIntegrations;
    environmentVariables = {
      SHELL = lib.getExe pkgs.nushell;
    };
  };
}
