#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

echo "=== Updating manual packages ==="
echo

# 1. GitHub-hosted packages (nix-update auto-discovers new releases)
echo "--- GitHub packages (system) ---"
for pkg in lulu blockblock; do
  echo "Checking $pkg..."
  nix-update --flake --file ./system "$pkg" || echo "  Warning: $pkg update failed, skipping"
  echo
done

# 2. Self-updating apps (custom version APIs, nix-update handles hash refresh)
echo "--- Self-updating system apps ---"

echo "Checking arturia-software-center..."
arturia_ver=$(curl -sL "https://www.arturia.com/api/resources?slugs=asc&types=soft" 2>/dev/null |
  python3 -c "import json,sys; data=json.load(sys.stdin); print(next(x['version'] for x in data if x.get('platform_type')=='mac'))" 2>/dev/null)
if [ -n "$arturia_ver" ]; then
  nix-update --flake --file ./system arturia-software-center --version "$arturia_ver" || echo "  Warning: arturia-software-center update failed, skipping"
else
  echo "  Failed to fetch Arturia version, skipping"
fi
echo

echo "Checking native-access..."
ni_ver=$(curl -sL "https://na-update.native-instruments.com/arm64/latest-mac.yml" 2>/dev/null | awk '/^version:/{print $2}' | tr -d '\r')
if [ -n "$ni_ver" ]; then
  nix-update --flake --file ./system native-access --version "$ni_ver" || echo "  Warning: native-access update failed, skipping"
else
  echo "  Failed to fetch Native Instruments version, skipping"
fi
echo

echo "Checking waves-central..."
waves_ver=$(curl -sL "https://register.waves.com/Autoupdate/Updates/ByProductId/1/latest-mac.yml" 2>/dev/null | awk '/^version:/{print $2}' | tr -d '\r')
if [ -n "$waves_ver" ]; then
  nix-update --flake --file ./system waves-central --version "$waves_ver" || echo "  Warning: waves-central update failed, skipping"
else
  echo "  Failed to fetch Waves version, skipping"
fi
echo

echo "--- GitHub packages (home) ---"
for pkg in pearcleaner pareto-security pi-mcp-adapter; do
  echo "Checking $pkg..."
  nix-update --flake --file ./home "$pkg" || echo "  Warning: $pkg update failed, skipping"
  echo
done

# 3. MacWhisper (no public API for build numbers)
echo "--- MacWhisper ---"
echo "Skipping: requires manual build number update (no public API)."
echo "To update manually: edit home/packages/macwhisper.nix version + build, then:"
echo "  nix-update --flake --file ./home macwhisper --version <ver>"
echo

# 4. Pi coding agent (npm package)
echo "--- Pi coding agent ---"
PI_NIX="home/configs/pi-coding-agent/default.nix"
PI_PKG_DIR="home/configs/pi-coding-agent/pi-package"
CURRENT_PI_VER=$(grep 'piVersion' "$PI_NIX" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
LATEST_PI_VER=$(npm view @mariozechner/pi-coding-agent version 2>/dev/null)

if [ -z "$LATEST_PI_VER" ]; then
  echo "  Failed to fetch latest version from npm, skipping"
elif [ "$CURRENT_PI_VER" = "$LATEST_PI_VER" ]; then
  echo "  Already at latest version ($CURRENT_PI_VER)"
else
  echo "  Updating $CURRENT_PI_VER -> $LATEST_PI_VER"

  # Update version in package.json
  sed -i "s/\"@mariozechner\/pi-coding-agent\": \"$CURRENT_PI_VER\"/\"@mariozechner\/pi-coding-agent\": \"$LATEST_PI_VER\"/" "$PI_PKG_DIR/package.json"
  sed -i "s/\"version\": \"$CURRENT_PI_VER\"/\"version\": \"$LATEST_PI_VER\"/" "$PI_PKG_DIR/package.json"

  # Regenerate lockfile
  (cd "$PI_PKG_DIR" && npm install --package-lock-only --ignore-scripts 2>/dev/null)

  # Compute new npmDepsHash
  PREFETCH=$(nix build --no-link --print-out-paths nixpkgs#prefetch-npm-deps 2>/dev/null)
  NEW_HASH=$("$PREFETCH/bin/prefetch-npm-deps" "$PI_PKG_DIR/package-lock.json" 2>/dev/null)

  if [ -z "$NEW_HASH" ]; then
    echo "  Warning: failed to compute npmDepsHash, manual fix needed"
  else
    # Update version and hash in nix file (target pi-coding-agent block specifically)
    OLD_HASH=$(awk '/pname = "pi-coding-agent"/{found=1} found && /npmDepsHash/{print; exit}' "$PI_NIX" | grep -oE 'sha256-[A-Za-z0-9+/=]+')
    sed -i "s/piVersion = \"$CURRENT_PI_VER\"/piVersion = \"$LATEST_PI_VER\"/" "$PI_NIX"
    sed -i "s|$OLD_HASH|$NEW_HASH|" "$PI_NIX"
    echo "  Updated to $LATEST_PI_VER"
  fi
fi
echo

echo "=== Done ==="
echo "Run 'nix flake check ./home' to verify updated packages."
