# Wrap npm commands with safe-chain for malware protection
# safe-chain intercepts package downloads and checks them against threat intelligence

def --env npm [...args] {
  safe-chain npm ...$args
}

def --env npx [...args] {
  safe-chain npx ...$args
}

def --env pnpm [...args] {
  safe-chain pnpm ...$args
}

def --env pnpx [...args] {
  safe-chain pnpx ...$args
}

def --env yarn [...args] {
  safe-chain yarn ...$args
}
