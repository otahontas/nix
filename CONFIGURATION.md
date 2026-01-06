# Configuration Structure

This repository uses completely separate flakes for home-manager (user config) and nix-darwin (system config).

## File Structure

```
.
├── home/                        # Home-manager flake (no sudo required)
│   ├── flake.nix                # Standalone home-manager flake
│   ├── flake.lock
│   ├── home-configuration.nix   # Home-manager module
│   └── modules/                 # User-level tool configurations
│       └── [tool]/[tool].nix    # Per-tool configurations (42 tools)
│
├── darwin/                      # nix-darwin flake (requires sudo)
│   ├── flake.nix                # Standalone nix-darwin flake
│   ├── flake.lock
│   ├── darwin-configuration.nix # System configuration module
│   └── modules/                 # System-level settings
│       ├── defaults.nix         # macOS system defaults
│       ├── nix-settings.nix     # Nix daemon settings
│       ├── nixpkgs.nix          # nixpkgs overlays and config
│       └── security.nix         # Security settings (TouchID, etc.)
│
├── justfile                     # Commands for both configurations
└── [other files]
```

## Configurations

### 1. Home-Manager (User Configuration - No Sudo)

Apply user-level configuration without sudo:

```bash
# From repository root
home-manager switch --flake ./home

# Or using justfile
just apply-home
```

This configuration:
- **No sudo required** - runs as your user
- System-agnostic (portable to Linux, other macOS systems, etc.)
- Manages all user-level tools and dotfiles from `home/modules/`
- Independent flake that can be used anywhere
- Perfect for non-admin scenarios or multi-system setups

### 2. nix-darwin (System Configuration - Requires Sudo)

Apply system-level configuration with sudo:

```bash
# From repository root
sudo darwin-rebuild switch --flake ./darwin

# Or using justfile (recommended - includes verification)
just apply
```

This configuration:
- **Requires sudo** - modifies system settings
- macOS-specific system management
- Manages system settings from `darwin/modules/`
- Integrates home-manager using the home flake
- Full control of macOS system preferences

## Justfile Commands

```bash
# Home-manager only
just apply-home          # Apply home config (no sudo)
just check-home          # Check home flake
just update-home         # Update home flake

# nix-darwin (includes verification)
just apply               # Build, verify, and apply darwin config (sudo)
just verify              # Lint and build darwin config
just check-darwin        # Check darwin flake
just update-darwin       # Update darwin flake

# Both
just check-flake         # Check both flakes
just update-flake        # Update both flakes
just lint                # Lint all nix files
just format              # Format all nix files
```

## Benefits of This Structure

1. **Complete Separation**: Two independent flakes, truly separate concerns
2. **Sudo Independence**: home-manager works without any privileges
3. **Portability**: home-manager flake works on any system (Linux, macOS, etc.)
4. **Flexibility**: Use just home-manager without nix-darwin, or both together
5. **Clear Ownership**: System stuff in `darwin/`, user stuff in `home/`
6. **Independent Updates**: Update home and darwin flakes separately

## Module Details

### home/home-configuration.nix

Imports all files from `home/modules/` and sets:
- Home-manager state version
- XDG base directory support
- Automatically discovers and imports all `.nix` files in `home/modules/`

Contains 42 user-level tool configurations including:
- Shell (nushell, starship)
- Editor (neovim)
- Git, SSH, GPG
- Development tools
- Terminal UI tools
- And more...

### darwin/darwin-configuration.nix

Imports all files from `darwin/modules/` and sets:
- System state version
- Automatically discovers and imports all `.nix` files in `darwin/modules/`

Contains system-level settings:
- macOS system defaults and preferences
- Nix daemon configuration
- Security settings (TouchID for sudo)
- nixpkgs overlays and unfree packages

## Adding New Configurations

### User-level (Portable)
Add `.nix` files to `home/modules/[toolname]/[toolname].nix` - auto-imported by home-configuration.nix

### System-level (macOS only)
Add `.nix` files to `darwin/modules/` - auto-imported by darwin-configuration.nix

## Workflow Examples

### Typical Development Workflow
1. Make changes to tool configs in `home/modules/`
2. Test: `just apply-home` (fast, no sudo)
3. Iterate until satisfied

### System Configuration Changes
1. Make changes in `darwin/modules/`
2. Verify: `just verify` (builds without applying)
3. Apply: `just apply` (requires sudo)

### Multi-System Setup
1. Clone repo on new system (e.g., Linux)
2. Only use: `home-manager switch --flake ./home`
3. Get all your tools and configs without system management
