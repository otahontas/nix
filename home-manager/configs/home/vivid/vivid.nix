{ pkgs, lib, ... }:
{
  catppuccin.vivid.enable = true;
  programs.vivid.enable = true;
  programs.nushell.extraEnv = builtins.readFile (
    pkgs.replaceVars ./env.nu.in {
      vivid_bin = lib.getExe pkgs.vivid;
    }
  );
}
