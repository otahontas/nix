{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    package =
      if pkgs.atuin.version == "18.23.0" then
        pkgs.atuin.overrideAttrs {
          doCheck = false;
        }
      else
        pkgs.atuin;
  };
}
