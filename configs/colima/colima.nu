# Docker credential helpers for pass integration

# Store Docker registry credentials in pass
def docker-login-pass [
  registry: string  # Registry URL (e.g., ghcr.io, docker.io)
  username: string  # Username for the registry
  --password-stdin  # Read password from stdin
] {
  let password = if $password_stdin {
    input
  } else {
    input --suppress-output $"Password for ($username)@($registry): "
  }

  # Store credentials in pass at docker-credentials/<registry>/<username>
  let pass_path = $"docker-credentials/($registry)/($username)"

  # Create JSON format that docker-credential-pass expects
  let creds = {
    ServerURL: $registry,
    Username: $username,
    Secret: $password
  } | to json

  # Store in pass
  $creds | ^pass insert -m $pass_path

  print $"Credentials stored in pass at: ($pass_path)"
}

# Retrieve Docker credentials from pass for a registry
def docker-get-pass [
  registry: string  # Registry URL
] {
  let pass_entries = ^pass ls $"docker-credentials/($registry)"
    | lines
    | where $it =~ $registry
    | parse "{path}"

  if ($pass_entries | is-empty) {
    error make {msg: $"No credentials found for registry: ($registry)"}
  }

  # Get the first matching entry
  let pass_path = $pass_entries.0.path | str replace "├── " "" | str replace "└── " ""
  ^pass show $pass_path | from json
}
