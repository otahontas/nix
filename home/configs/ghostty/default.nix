{ config, ... }:
{
  programs.ghostty = {
    enable = true;
    package = null; # skip nix package on mac, use brew cask instead
    settings = {
      macos-option-as-alt = "left";
    };
  };

  # Ghostty on macOS looks for config in Application Support, symlink to XDG location
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty/config";
}
