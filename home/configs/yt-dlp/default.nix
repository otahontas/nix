_: {
  programs.yt-dlp = {
    enable = true;
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
