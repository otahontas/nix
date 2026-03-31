#!/usr/bin/env bash
# Update manually-pinned packages that aren't covered by `nix flake update`.
# - pi-coding-agent: npm package with local package.json wrapper
# - pi-mcp-adapter, pi-web-access: GitHub packages exposed via home flake
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PI_PKG_DIR="$REPO_ROOT/home/configs/pi-coding-agent"
PI_NIX="$PI_PKG_DIR/default.nix"
PI_PACKAGE_JSON="$PI_PKG_DIR/pi-package/package.json"

update_pi_coding_agent() {
  local current latest
  current=$(jq -r '.dependencies["@mariozechner/pi-coding-agent"]' "$PI_PACKAGE_JSON")
  latest=$(npm view @mariozechner/pi-coding-agent version)

  if [[ $current == "$latest" ]]; then
    echo "pi-coding-agent: already at $current"
    return
  fi

  echo "pi-coding-agent: $current -> $latest"

  # Update package.json
  jq --arg v "$latest" '.version = $v | .dependencies["@mariozechner/pi-coding-agent"] = $v' \
    "$PI_PACKAGE_JSON" >"$PI_PACKAGE_JSON.tmp"
  mv "$PI_PACKAGE_JSON.tmp" "$PI_PACKAGE_JSON"

  # Update version in nix file
  sed -i '' "s/version = \"$current\"/version = \"$latest\"/" "$PI_NIX"

  # Regenerate lockfile
  (cd "$PI_PKG_DIR/pi-package" && npm install --package-lock-only)

  # Compute new npmDepsHash with a dummy hash to get the real one
  local real_hash
  real_hash=$(
    nix build --no-link --impure --expr "
      let pkgs = import <nixpkgs> {};
      in pkgs.buildNpmPackage {
        pname = \"pi-wrapper\";
        version = \"$latest\";
        src = $PI_PKG_DIR/pi-package;
        npmDepsHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
        dontNpmBuild = true;
      }
    " 2>&1 | grep 'got:' | awk '{print $2}'
  )

  if [[ -z $real_hash ]]; then
    echo "ERROR: failed to compute npmDepsHash" >&2
    return 1
  fi

  # Update npmDepsHash in nix file
  sed -i '' "s|npmDepsHash = \".*\"|npmDepsHash = \"$real_hash\"|" "$PI_NIX"
  echo "pi-coding-agent: updated to $latest"
}

update_flake_packages() {
  local pkg="$1"
  echo "Updating $pkg via nix-update..."
  (cd "$REPO_ROOT/home" && nix-update --flake "$pkg")
}

echo "=== Updating manually-pinned packages ==="
update_pi_coding_agent
update_flake_packages pi-mcp-adapter
update_flake_packages pi-web-access
echo "=== Done ==="
