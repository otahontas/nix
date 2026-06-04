{ config, pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      macos-option-as-alt = "left";
      bell-features = "title,attention,border";
    };
  };

  # Ghostty on macOS looks for config in Application Support, symlink to XDG location
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty/config";
}
