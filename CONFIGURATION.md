# Configuration Structure

This repository uses a modular approach to separate nix-darwin and home-manager configurations.

## File Structure

```
.
├── flake.nix                    # Main flake orchestrator
├── darwin-configuration.nix     # nix-darwin system configuration module
├── home-configuration.nix       # home-manager user configuration module
├── configs/
│   ├── system/                  # nix-darwin specific settings
│   │   ├── defaults.nix         # macOS system defaults
│   │   ├── nix-settings.nix     # Nix daemon settings
│   │   ├── nixpkgs.nix          # nixpkgs overlays and config
│   │   └── security.nix         # Security settings (TouchID, etc.)
│   └── home/                    # home-manager user configs
│       └── [tool]/[tool].nix    # Per-tool configurations
```

## Configurations

### 1. Standalone Home-Manager (Linux, other macOS systems)

Use the standalone home-manager configuration:

```bash
home-manager switch --flake .#otahontas
```

This configuration:
- Is system-agnostic (works on Linux, other macOS, etc.)
- Includes all user-level tools and settings from `configs/home/`
- Does not require nix-darwin
- Good for non-macOS systems or when you don't need system-level management

### 2. nix-darwin with Integrated Home-Manager (Primary macOS)

Use the full system configuration (default):

```bash
darwin-rebuild switch --flake .#otabook-work
# or
just apply
```

This configuration:
- Manages macOS system settings via nix-darwin
- Includes home-manager as a darwinModule
- Provides both system and user configuration
- Primary setup for `otabook-work` machine

## Benefits of This Structure

1. **Clear Separation**: System config (darwin-configuration.nix) vs user config (home-configuration.nix)
2. **Reusability**: home-manager config can be used standalone on other systems
3. **Maintainability**: Each module is self-contained with clear responsibilities
4. **Flexibility**: Choose between standalone home-manager or integrated nix-darwin setup

## Module Details

### darwin-configuration.nix

Imports all files from `configs/system/` and sets:
- System state version
- Automatically discovers and imports all `.nix` files in `configs/system/`

Contains:
- macOS system defaults
- Nix daemon configuration
- Security settings
- nixpkgs overlays and config

### home-configuration.nix

Imports all files from `configs/home/` and sets:
- Home-manager state version
- XDG base directory support
- Automatically discovers and imports all `.nix` files in `configs/home/`

Contains:
- All user-level tool configurations
- Shell configurations
- Editor settings
- Development tools

## Adding New Configurations

### System-level (macOS only)
Add `.nix` files to `configs/system/` - they will be auto-imported by `darwin-configuration.nix`

### User-level (portable)
Add tool configs to `configs/home/[toolname]/[toolname].nix` - they will be auto-imported by `home-configuration.nix`
