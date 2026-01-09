nix-darwin system-level config for macOS, includes:

- System defaults (login, startup)
- Homebrew management - brew itself and all packages installed through nix-darwin, never use `brew` CLI directly
- Homebrew casks + MAS apps
- Custom Homebrew taps - add as flake inputs (see `tonisives-tap` example in flake.nix)
- User accounts (admin + primary)
- Firewall + networking
- Custom keyboard layouts (`./keyboard`)

Requires admin privileges - always ask user to apply the changes, never apply yourself.
