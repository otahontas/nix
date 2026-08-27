{
  config,
  lib,
  pkgs,
  ...
}:

let
  mergeSettings = pkgs.writeShellScript "discord-merge-settings" ''
    set -euo pipefail

    settings_file="${config.home.homeDirectory}/Library/Application Support/discord/settings.json"
    mkdir -p "$(dirname "$settings_file")"

    if [ ! -f "$settings_file" ]; then
      printf '{}\n' >"$settings_file"
    fi

    tmp="$settings_file.tmp"
    ${pkgs.jq}/bin/jq '. + {SKIP_HOST_UPDATE: true}' "$settings_file" >"$tmp"
    mv "$tmp" "$settings_file"
  '';
in
{
  home.packages = [ pkgs.brewCasks.discord ];

  home.activation.discordDisableHostUpdates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${mergeSettings}
  '';
}
