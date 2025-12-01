# Wrap npm commands with safe-chain for malware protection
# These wrappers call aikido-* binaries that intercept package downloads
# and check them against threat intelligence before installation

def --env npm [...args] {
  aikido-npm ...$args
}

def --env npx [...args] {
  aikido-npx ...$args
}

def --env pnpm [...args] {
  aikido-pnpm ...$args
}

def --env pnpx [...args] {
  aikido-pnpx ...$args
}

def --env yarn [...args] {
  aikido-yarn ...$args
}

def --env bun [...args] {
  aikido-bun ...$args
}

def --env bunx [...args] {
  aikido-bunx ...$args
}
