# System config

nix-darwin flake in `system/`. Manages macOS defaults, user accounts, firewall, nix daemon, keyboard layouts.

Requires sudo. Apply with `devenv tasks run system:apply`.

## What it configures

macOS defaults and daemon settings managed here.

- Finder, Dock, trackpad, screencapture defaults
- Nix daemon — gc schedule, substituters, experimental features
- TouchID for sudo via PAM
- Firewall with stealth mode
- Fish as default shell
- Custom keyboard layout in `system/keyboard/`
