{ pkgs, ... }:
let
  listening = pkgs.writeShellScriptBin "listening" ''
    if [ -n "$1" ]; then
      lsof -iTCP -sTCP:LISTEN -n -P | grep -i "$1"
    else
      lsof -iTCP -sTCP:LISTEN -n -P
    fi
  '';

  nukeport = pkgs.writeShellScriptBin "nukeport" ''
    if [ -z "$1" ]; then
      echo "Usage: nukeport <port>"
      exit 1
    fi

    pids=$(lsof -ti :"$1" | sort -u)

    if [ -z "$pids" ]; then
      echo "No process found on port $1"
      exit 0
    fi

    for pid in $pids; do
      echo "Killing PID $pid on port $1"
      kill -9 "$pid"
    done

    echo "✓ Port $1 freed"
  '';

  trash-empty = pkgs.writeShellScriptBin "trash-empty" ''
    read -r -p "Empty Trash? [y/N] " response
    case_response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    case "$case_response" in
      y|yes)
        if osascript -e 'tell application "Finder" to empty trash' 2>/dev/null; then
          echo "✓ Trash emptied"
        else
          echo "✗ Failed to empty trash"
          exit 1
        fi
        ;;
      *)
        echo Cancelled
        ;;
    esac
  '';
in
{
  home.packages = [
    listening
    nukeport
    trash-empty
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;
  };
}
