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

echo "--- GitHub packages (home) ---"
for pkg in pearcleaner pareto-security; do
  echo "Checking $pkg..."
  nix-update --flake --file ./home "$pkg" || echo "  Warning: $pkg update failed, skipping"
  echo
done

# 2. Firefox Developer Edition (version from Mozilla Archive)
echo "--- Firefox Developer Edition ---"
echo "Fetching latest version from archive.mozilla.org..."
FIREFOX_VER="$(
  curl -fsSL "https://archive.mozilla.org/pub/devedition/releases/" |
    grep -oE '/pub/devedition/releases/[0-9][0-9.]*b[0-9]+/' |
    cut -d'/' -f5 |
    sort -V |
    tail -n 1 || true
)"

if [ -n "$FIREFOX_VER" ]; then
  echo "Latest Firefox DevEdition: $FIREFOX_VER"
  nix-update --flake --file ./home firefox-devedition-bin --version "$FIREFOX_VER" ||
    echo "  Warning: firefox-devedition-bin update failed, skipping"
else
  echo "  Failed to determine latest Firefox DevEdition version"
fi
echo

# 3. MacWhisper (no public API for build numbers)
echo "--- MacWhisper ---"
echo "Skipping: requires manual build number update (no public API)."
echo "To update manually: edit home/packages/macwhisper.nix version + build, then:"
echo "  nix-update --flake --file ./home macwhisper --version <ver>"
echo

echo "=== Done ==="
echo "Run 'nix flake check ./home' to verify updated packages."
