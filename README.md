# Nix Configuration

Personal nix-darwin and home-manager configurations for macOS.

## Quick Start

### Apply User Configuration (No Sudo)
```bash
home-manager switch --flake ./home
# or
just apply-home
```

### Apply System Configuration (Requires Sudo)
```bash
sudo darwin-rebuild switch --flake ./darwin
# or
just apply
```

## Structure

This repository contains **two separate flakes**:

- **`home/`** - Home-manager configuration (user-level, no sudo, portable)
- **`darwin/`** - nix-darwin configuration (system-level, requires sudo, macOS-specific)

See [CONFIGURATION.md](CONFIGURATION.md) for detailed documentation.

## Common Commands

```bash
# User configuration
just apply-home      # Apply home-manager config (no sudo)

# System configuration  
just apply           # Build, verify, and apply nix-darwin (sudo)
just verify          # Lint and build without applying

# Maintenance
just format          # Format all Nix files
just lint            # Lint all files
just update-flake    # Update both flakes
just clean           # Clean up old generations
```

## Documentation

- [CONFIGURATION.md](CONFIGURATION.md) - Detailed structure and usage
- [AGENTS.md](AGENTS.md) - Development guidelines
- [CLAUDE.md](CLAUDE.md) - AI assistant guidelines
