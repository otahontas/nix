{ config, ... }:
{
  home.file = {
    ".pi/agent/sessions".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/pi-coding-agent-sessions";
    "Music/Audio Music Apps".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/Audio Music Apps";
    "Music/MainStage".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/MainStage";
  };
}
