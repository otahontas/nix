{ config, ... }:
{
  home.file = {
    ".pi/agent/sessions".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/pi-coding-agent-sessions";
    "Music/Audio Music Apps".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/Audio Music Apps";
    "Music/Logic".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/Logic";
    "Music/MainStage".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/MainStage";
    "Music/MuseScore4".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/MuseScore4";
  };
}
