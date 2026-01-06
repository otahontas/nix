# Configuration Splitting - Implementation Summary

## Problem Statement
The repository previously had a single monolithic `flake.nix` that combined both nix-darwin (system) and home-manager (user) configurations. The goal was to implement a complete separation into two independent flakes that can be managed separately.

## Solution Implemented

### Two Completely Separate Flakes

1. **Root `flake.nix`** - nix-darwin system-level configuration
   - Requires sudo
   - Manages macOS system settings only
   - References only `configs/system/` modules
   - Completely independent of home-manager

2. **`home-manager/flake.nix`** - home-manager user-level configuration
   - No sudo required
   - Manages user environment, packages, and dotfiles
   - References `home-manager/configs/home/` modules
   - Completely independent of nix-darwin
   - Can be used on any machine

### Directory Structure

```
.
├── flake.nix                          # nix-darwin (sudo)
├── darwin-configuration.nix           # System module
├── configs/
│   ├── system/                        # System configs (nix-darwin)
│   └── home/                          # Legacy (for reference)
└── home-manager/                      # Separate flake
    ├── flake.nix                      # home-manager (no sudo)
    ├── flake.lock                     # Independent lock file
    └── configs/
        └── home/                      # User configs (home-manager)
```

### Key Changes

#### Root flake.nix
- Stripped down to only nix-darwin configuration
- Removed all home-manager integration
- Only references system-level inputs (nix-darwin, nixpkgs)
- Manages system state and user accounts only

#### home-manager/flake.nix
- New standalone flake for user configuration
- Contains all home-manager specific inputs (catppuccin, neovim-nightly-overlay, etc.)
- Manages user packages, dotfiles, and environment
- Platform-agnostic (could work on Linux/NixOS)

#### justfile
- Updated with separate commands:
  - `just apply-darwin` - Apply system config (sudo)
  - `just apply-home` - Apply user config (no sudo)
  - `just apply` - Apply both (system then user)
  - `just check-flake` - Check both flakes

### Benefits

1. **Complete Separation**: System and user configurations are totally independent
2. **No Sudo for User Changes**: Most day-to-day changes don't require root
3. **Independent Updates**: Update user environment without system rebuild
4. **Better Performance**: Smaller rebuilds, faster iterations
5. **Clear Responsibility**: System vs user concerns are never mixed
6. **Portability**: Home config can be used on any machine
7. **Flexibility**: Can run either config independently

### Usage

#### System Configuration (requires sudo)
```bash
cd /path/to/repo
git add .
sudo darwin-rebuild switch --flake .
# Or: just apply-darwin
```

#### User Configuration (no sudo)
```bash
cd /path/to/repo/home-manager
git add .
home-manager switch --flake .#otahontas
# Or: just apply-home
```

#### Both Together
```bash
cd /path/to/repo
just apply  # Runs darwin then home-manager
```

### Backward Compatibility

Breaking changes (intentional):
- `just apply` now runs both configs sequentially
- Home configs moved to `home-manager/` directory
- Two separate flake.lock files to manage
- Need to specify which config to update

Benefits of breaking changes:
- Clearer separation of concerns
- Most changes only need `just apply-home` (no sudo)
- Faster iteration on user config
- Can update system and user packages independently

### Future Improvements

Possible next steps:
1. Support for multiple machines/users through parameters
2. NixOS configuration using the same home-manager flake
3. Share flake inputs between darwin and home-manager (if desired)
4. Per-machine overrides while keeping shared configuration

## Files Changed

- `flake.nix` - Simplified to darwin-only
- `home-manager/flake.nix` - NEW: Standalone home-manager flake
- `home-manager/flake.lock` - NEW: Independent lock file
- `home-manager/configs/home/` - NEW: Copied user configs
- `darwin-configuration.nix` - Updated to reference only system configs
- `home-configuration.nix` - REMOVED: No longer needed
- `justfile` - Updated with separate apply commands
- `README.md` - Comprehensive documentation of new structure
- `CLAUDE.md` - Updated with new structure
- `AGENTS.md` - Updated with new structure

## Testing Recommendation

To verify these changes work correctly:
1. Stage changes: `git add .`
2. Check darwin flake: `nix flake check`
3. Check home flake: `cd home-manager && nix flake check`
4. Build darwin config: `darwin-rebuild build --flake .`
5. Apply darwin config: `sudo darwin-rebuild switch --flake .`
6. Apply home config: `cd home-manager && home-manager switch --flake .#otahontas`
