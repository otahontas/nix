# Nix Configuration

This repository contains my personal nix-darwin and home-manager configuration for macOS with Nushell.

## Structure

The configuration is split into separate concerns:

```
.
├── flake.nix                    # Main flake with both nix-darwin and home-manager outputs
├── darwin-configuration.nix     # nix-darwin system-level configuration
├── home-configuration.nix       # home-manager user-level configuration (standalone-capable)
├── configs/
│   ├── system/                  # System-level modules (nix-darwin)
│   │   ├── defaults.nix         # macOS system defaults
│   │   ├── nix-settings.nix     # Nix daemon settings
│   │   ├── nixpkgs.nix          # Nixpkgs overlays and config
│   │   └── security.nix         # Security settings (Touch ID, etc.)
│   └── home/                    # User-level modules (home-manager)
│       └── [tool]/[tool].nix    # Individual tool configurations
```

## Usage

### Full system configuration (nix-darwin + home-manager)

```bash
git add .  # Required for flake to see uncommitted changes
just apply
```

Or manually:
```bash
darwin-rebuild switch --flake ~/.config/nix-darwin
```

### Standalone home-manager

The home-manager configuration can also be used independently without nix-darwin:

```bash
home-manager switch --flake .#otahontas
```

This is useful for:
- Testing home-manager changes without affecting system config
- Using the same home configuration on non-Darwin systems
- Sharing configurations across different machines

## Benefits of this separation

1. **Modularity**: System and user configurations are clearly separated
2. **Reusability**: Home configuration can be used standalone or integrated with nix-darwin
3. **Clarity**: Easier to understand what changes affect system vs user level
4. **Flexibility**: Can test home-manager changes independently
5. **Portability**: Home configuration could be adapted for non-Darwin systems (Linux, NixOS)

## Package Management

- All packages are managed through Nix (nix-darwin or home-manager)
- Prefer home-manager for user-level packages
- Never use Homebrew

## Development

See [CLAUDE.md](CLAUDE.md) and [AGENTS.md](AGENTS.md) for detailed conventions and guidelines.
