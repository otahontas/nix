{ config, ... }:
{
  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/.cache/go";
  };
}
