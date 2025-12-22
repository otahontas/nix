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
    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        algorithm = "fuzzy";
        quick = true;
        partial = true;
        use_ls_colors = true;
      };
      history = {
        max_size = 10000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
      cursor_shape = {
        vi_insert = "line";
        vi_normal = "block";
      };
    };
  };
}
