{ pkgs, ... }:
{
  home.packages = with pkgs; [
    act # GitHub Actions local runner
  ];
}
