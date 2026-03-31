#!/usr/bin/env bash
# Update manually-pinned packages that aren't covered by `nix flake update`.
# - pi-coding-agent: npm package with local package.json wrapper
# - pi-mcp-adapter: GitHub npm package exposed via home flake
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- pi-coding-agent (npm registry) ---

update_pi_coding_agent() {
  local pkg_dir="$REPO_ROOT/home/configs/pi-coding-agent"
  local nix_file="$pkg_dir/default.nix"
  local pkg_json="$pkg_dir/pi-package/package.json"

  local current latest
  current=$(jq -r '.dependencies["@mariozechner/pi-coding-agent"]' "$pkg_json")
  latest=$(npm view @mariozechner/pi-coding-agent version)

  if [[ $current == "$latest" ]]; then
    echo "pi-coding-agent: already at $current"
    return
  fi

  echo "pi-coding-agent: $current -> $latest"

  # Update package.json
  jq --arg v "$latest" \
    '.version = $v | .dependencies["@mariozechner/pi-coding-agent"] = $v' \
    "$pkg_json" >"$pkg_json.tmp"
  mv "$pkg_json.tmp" "$pkg_json"

  # Update version in nix file
  sed -i '' "s/version = \"$current\"/version = \"$latest\"/" "$nix_file"

  # Regenerate lockfile
  (cd "$pkg_dir/pi-package" && npm install --package-lock-only)

  # Compute new npmDepsHash
  local npm_hash
  npm_hash=$(compute_npm_deps_hash "$pkg_dir/pi-package" "$latest")
  sed -i '' "s|npmDepsHash = \".*\"|npmDepsHash = \"$npm_hash\"|" "$nix_file"

  echo "pi-coding-agent: updated to $latest"
}

# --- GitHub npm packages (pi-mcp-adapter) ---

update_github_npm_package() {
  local name="$1"
  local owner="$2"
  local repo="$3"
  local nix_file="$REPO_ROOT/home/packages/$name.nix"

  local current latest
  current=$(grep 'version = ' "$nix_file" | head -1 | sed 's/.*"\(.*\)".*/\1/')
  latest=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name' | sed 's/^v//')

  if [[ $current == "$latest" ]]; then
    echo "$name: already at $current"
    return
  fi

  echo "$name: $current -> $latest"

  # Get new src hash
  local src_hash
  src_hash=$(nix-prefetch-url --unpack \
    "https://github.com/$owner/$repo/archive/refs/tags/v$latest.tar.gz" 2>/dev/null)
  src_hash=$(nix hash convert --hash-algo sha256 --to sri "$src_hash")

  # Update version, rev, hash in nix file
  sed -i '' "s/version = \"$current\"/version = \"$latest\"/" "$nix_file"
  sed -i '' "s/rev = \"v$current\"/rev = \"v$latest\"/" "$nix_file"
  sed -i '' "s|hash = \"sha256-.*\"|hash = \"$src_hash\"|" "$nix_file"

  # Compute new npmDepsHash
  local npm_hash
  npm_hash=$(nix build --no-link --impure --expr "
    let pkgs = import <nixpkgs> {};
    in (pkgs.buildNpmPackage {
      pname = \"$name\";
      version = \"$latest\";
      src = pkgs.fetchFromGitHub {
        owner = \"$owner\";
        repo = \"$repo\";
        rev = \"v$latest\";
        hash = \"$src_hash\";
      };
      npmDepsHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
      dontNpmBuild = true;
    }).npmDeps
  " 2>&1 | grep 'got:' | awk '{print $2}')

  if [[ -z $npm_hash ]]; then
    echo "ERROR: failed to compute npmDepsHash for $name" >&2
    return 1
  fi

  sed -i '' "s|npmDepsHash = \".*\"|npmDepsHash = \"$npm_hash\"|" "$nix_file"

  echo "$name: updated to $latest"
}

# --- Helpers ---

compute_npm_deps_hash() {
  local src_path="$1"
  local version="$2"

  local hash
  hash=$(nix build --no-link --impure --expr "
    let pkgs = import <nixpkgs> {};
    in pkgs.buildNpmPackage {
      pname = \"pi-wrapper\";
      version = \"$version\";
      src = $src_path;
      npmDepsHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
      dontNpmBuild = true;
    }
  " 2>&1 | grep 'got:' | awk '{print $2}')

  if [[ -z $hash ]]; then
    echo "ERROR: failed to compute npmDepsHash" >&2
    return 1
  fi

  echo "$hash"
}

# --- Main ---

echo "=== Updating manually-pinned packages ==="
update_pi_coding_agent
update_github_npm_package pi-mcp-adapter nicobailon pi-mcp-adapter
echo "=== Done ==="
