{ pkgs, lib, ... }:
let
  yt-dlp-wrapped = pkgs.writeShellScriptBin "yt-dlp" ''
    exec ${lib.getExe pkgs.yt-dlp} "$@"
  '';
in
{
  programs.yt-dlp = {
    enable = true;
    package = yt-dlp-wrapped;
    settings = {
      # Best quality video + audio
      format = "bestvideo+bestaudio/best";

      # Merge into single file
      merge-output-format = "mkv";

      # Prefer free formats over proprietary
      prefer-free-formats = true;

      # Add metadata
      add-metadata = true;
      embed-thumbnail = true;
      embed-subs = true;
      embed-chapters = true;

      # Download subtitles
      write-auto-subs = true;
      sub-langs = "en,en-US";

      # Continue downloads
      continue = true;

      # Don't overwrite files
      no-overwrites = true;

    };
  };
}
