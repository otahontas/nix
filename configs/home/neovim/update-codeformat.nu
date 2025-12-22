#!/usr/bin/env nu

# Update EmmyLuaCodeStyle (codeformat) version in neovim.nix

def main [] {
  let nix_file = ($env.FILE_PWD | path join "neovim.nix")
  let repo = "CppCXY/EmmyLuaCodeStyle"

  # Extract current version from neovim.nix
  let content = (open $nix_file)
  let current = ($content | parse --regex 'codeformat = pkgs\.stdenv\.mkDerivation rec \{\s*pname = "codeformat";\s*version = "([^"]+)"' | get 0.capture0)

  # Get latest release
  let latest = (gh release list -R $repo -L 1 --json tagName | from json | get 0.tagName)

  if $latest == $current {
    print $"✓ codeformat: ($current) \(up to date\)"
    return
  }

  print $"⬆ codeformat: ($current) → ($latest)"
  print "  Prefetching new hash..."

  let url = $"https://github.com/($repo)/releases/download/($latest)/darwin-arm64.tar.gz"
  let hash_result = (nix-prefetch-url --unpack $url 2>/dev/null | complete)

  if $hash_result.exit_code != 0 {
    print $"  ✗ Failed to prefetch: ($hash_result.stderr)"
    return
  }

  # Convert to SRI hash format
  let sri = (nix hash convert --hash-algo sha256 --to sri ($hash_result.stdout | str trim) | str trim)

  print $"  New hash: ($sri)"
  print "  Updating neovim.nix..."

  # Update version
  let updated = ($content | str replace $'version = "($current)"' $'version = "($latest)"')
  # Update sha256
  let updated = ($updated | str replace --regex 'sha256 = "sha256-[^"]+"' $'sha256 = "($sri)"')

  $updated | save --force $nix_file

  print "  ✓ Updated neovim.nix"
}
