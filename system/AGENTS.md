nix-darwin system-level config for macOS, includes:

- System defaults (login, startup)
- User accounts (admin + primary)
- Firewall + networking
- Custom keyboard layouts (`./keyboard`)

All CLI and GUI apps are managed through home-manager, not this config.

Requires admin privileges - always ask user to apply the changes, never apply yourself.
