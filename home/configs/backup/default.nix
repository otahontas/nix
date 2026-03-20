{ pkgs, ... }:
let
  periodicBackup = pkgs.writeShellScriptBin "periodic-backup" ''
    set -euo pipefail

    host_name="$(
      /usr/sbin/scutil --get LocalHostName 2>/dev/null || ${pkgs.coreutils}/bin/hostname -s
    )"

    extra_flags=()
    if [ "''${1:-}" = "--dry-run" ]; then
      extra_flags+=(--dry-run)
    fi

    backup() {
      local src="$1" dest="$2"
      if [ ! -d "$src" ]; then
        echo "Source not found, skipping: $src" >&2
        return
      fi
      ${pkgs.coreutils}/bin/mkdir -p "$dest"
      echo "Backing up: $src -> $dest"
      ${pkgs.rsync}/bin/rsync -a --exclude ".DS_Store" "''${extra_flags[@]}" "$src/" "$dest/"
    }

    # --- Backup destination ---
    backup_dest="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

    # --- Backup entries ---
    backup "''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/sessions" "$backup_dest/pi-sessions/$host_name"
  '';
in
{
  home.packages = [ periodicBackup ];

  launchd.agents.periodic-backup = {
    enable = true;
    config = {
      Label = "com.otahontas.periodic-backup";
      ProgramArguments = [ "${periodicBackup}/bin/periodic-backup" ];
      StartInterval = 86400;
      RunAtLoad = true;
      StandardOutPath = "/Users/otahontas/Library/Logs/periodic-backup.log";
      StandardErrorPath = "/Users/otahontas/Library/Logs/periodic-backup.log";
    };
  };
}
