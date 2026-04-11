---
id: pshs-kbme
status: closed
deps: [pshs-bwaw]
links: []
created: 2026-04-10T13:52:46Z
type: feature
priority: 2
assignee: Otto Ahoniemi
parent: pshs-erua
tags: [ready-for-development]
---

# Add launchd timer for automatic index rebuilding

Add a launchd agent to `home/configs/pi-coding-agent/default.nix` that runs the index builder every 2 hours.

The agent config:

```nix
launchd.agents.pi-session-indexer = {
  enable = true;
  config = {
    ProgramArguments = [ "${pkgs.bash}/bin/bash" "${./scripts/build-session-index.sh}" ];
    StartInterval = 7200;
    RunAtLoad = true;
    StandardOutPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
    StandardErrorPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
    ProcessType = "Background";
    LowPriorityIO = true;
  };
};
```

Add this block inside the existing `{ ... }` in `home/configs/pi-coding-agent/default.nix`.
The launchd module is already available in home-manager (confirmed at `/nix/store/hf3pbi5slrbx5p41w8sazvgxm8lbci0c-home-manager-source/modules/launchd/default.nix`).

## Acceptance Criteria

1. launchd agent config added to `home/configs/pi-coding-agent/default.nix`
2. `devenv tasks run home:apply` succeeds without errors
3. Agent is registered: `launchctl list | grep pi-session` shows the agent
4. Agent runs on load: index file exists after apply
5. Agent is set to run every 7200 seconds (2 hours)
6. Logs go to `~/.cache/pi-session-indexer.log`

## Notes

**2026-04-11T01:21:36Z**

Added launchd agent pi-session-indexer to default.nix. Runs build-session-index.sh every 2h with RunAtLoad. Logs to ~/.cache/pi-session-indexer.log. Verified: agent registered, index built on load, logs working.
