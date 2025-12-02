#!/usr/bin/env nu

# Generate .npmrc from pass stored token
# This script fetches NPM token from password-store and generates ~/.npmrc

def main [pass_bin: string] {
  # Get NPM token from pass
  let token = try {
    ^$pass_bin show npm/token | str trim
  } catch {
    error make {msg: "Failed to read NPM token from pass. Make sure 'pass show npm/token' works"}
  }

  if ($token | is-empty) {
    error make {msg: "NPM token is empty in pass"}
  }

  # Generate .npmrc content
  let npmrc = $"//registry.npmjs.org/:_authToken=($token)"

  # Write to .npmrc
  $npmrc | save -f ~/.npmrc

  # Set restrictive permissions
  ^chmod 600 ~/.npmrc

  print "NPM config generated successfully at ~/.npmrc"
}
