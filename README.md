# Nix Configuration

This repository contains my personal nix-darwin and home-manager configurations for macOS with Nushell.

## Structure

The configuration is split into **two completely separate flakes**:

```
.
├── flake.nix                    # nix-darwin system-level configuration (requires sudo)
├── darwin-configuration.nix     # System-level module
├── configs/
│   ├── system/                  # System-level modules (nix-darwin)
│   │   ├── defaults.nix         # macOS system defaults
│   │   ├── nix-settings.nix     # Nix daemon settings
│   │   ├── nixpkgs.nix          # Nixpkgs overlays and config
│   │   └── security.nix         # Security settings (Touch ID, etc.)
│   └── home/                    # User-level modules (kept for reference)
└── home-manager/                # Separate home-manager configuration
    ├── flake.nix                # home-manager user-level configuration (no sudo)
    └── configs/
        └── home/                # User-level modules (home-manager)
            └── [tool]/[tool].nix
```

## Why Two Separate Flakes?

1. **Clear separation**: System and user concerns are completely independent
2. **No sudo for user config**: Home-manager can be applied without root privileges
3. **Independent updates**: Update user environment without system rebuild
4. **Better isolation**: System changes don't trigger user config rebuilds
5. **Flexibility**: Run home-manager on any machine without nix-darwin

## Usage

### System Configuration (nix-darwin)

Requires sudo, manages macOS system settings:

```bash
# From repository root
cd /path/to/repo
git add .
sudo darwin-rebuild switch --flake .
```

### User Configuration (home-manager)

No sudo required, manages user packages and dotfiles:

```bash
# From home-manager directory
cd /path/to/repo/home-manager
git add .
home-manager switch --flake .#otahontas
```

### Recommended Workflow

1. Apply system changes (when needed):
   ```bash
   cd /path/to/repo
   git add .
   sudo darwin-rebuild switch --flake .
   ```

2. Apply user changes (more frequent):
   ```bash
   cd /path/to/repo/home-manager
   git add .
   home-manager switch --flake .#otahontas
   ```

## Package Management

- All packages are managed through Nix (nix-darwin or home-manager)
- User packages go in home-manager configuration
- System-level services go in nix-darwin configuration
- Never use Homebrew

## Development

See [CLAUDE.md](CLAUDE.md) and [AGENTS.md](AGENTS.md) for detailed conventions and guidelines.

