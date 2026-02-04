{ pkgs, lib, ... }:
let
  masApps = [
    {
      name = "Logic Pro";
      id = 634148309;
    }
    {
      name = "Lungo";
      id = 1263070803;
    }
    {
      name = "MainStage";
      id = 634159523;
    }
    {
      name = "Paprika Recipe Manager 3";
      id = 1303222628;
    }
    {
      name = "Telegram";
      id = 747648890;
    }
    {
      name = "Slack";
      id = 803453959;
    }
    {
      name = "Velja";
      id = 1607635845;
    }
    {
      name = "WhatsApp Messenger";
      id = 310633997;
    }
    {
      name = "WireGuard";
      id = 1451685025;
    }
    {
      name = "iReal Pro";
      id = 409035833;
    }
    {
      name = "reMarkable desktop";
      id = 1276493162;
    }
  ];

  masAppIds = map (app: toString app.id) masApps;
  masAppIdList = lib.concatStringsSep " " masAppIds;
in
{
  home.packages = [ pkgs.mas ];

  home.activation.installMasApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.mas}/bin/mas account >/dev/null 2>&1; then
      echo "mas: sign in to the App Store to install apps" >&2
      exit 0
    fi

    installed_ids="$(${pkgs.mas}/bin/mas list | /usr/bin/awk '{print $1}')"

    for app_id in ${masAppIdList}; do
      if echo "$installed_ids" | /usr/bin/grep -qx "$app_id"; then
        continue
      fi

      $DRY_RUN_CMD ${pkgs.mas}/bin/mas install "$app_id" || true
    done
  '';
}
