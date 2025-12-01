{ pkgs, ... }:
{
  home.packages = with pkgs; [
    act # GitHub Actions local runner
  ];

  home.file.".config/act/actrc".source = ./act/actrc;
}
