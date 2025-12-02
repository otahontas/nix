#!/usr/bin/env nu
def main [pass_bin: string] {
  let token = try {
    ^$pass_bin show npm/token | str trim
  } catch {
    error make {msg: "Failed to read NPM token from pass. Make sure 'pass show npm/token' works"}
  }

  if ($token | is-empty) {
    error make {msg: "NPM token is empty in pass"}
  }

  let npmrc = $"//registry.npmjs.org/:_authToken=($token)"

  $npmrc | save -f ~/.npmrc

  ^chmod 600 ~/.npmrc

  print "NPM config generated successfully at ~/.npmrc"
}
