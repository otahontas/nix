#!/usr/bin/env nu

# Generate AWS config from pass stored metadata
# This script fetches AWS metadata from password-store and generates ~/.aws/config

def main [pass_bin: string] {
  # Get metadata from pass
  let metadata = ^$pass_bin show mindler/aws/config-metadata | lines | parse "{key}: {value}"

  if ($metadata | is-empty) {
    error make {msg: "Failed to read AWS metadata from pass. Make sure 'pass show mindler/aws/config-metadata' works"}
  }

  # Helper to get value from metadata
  def get-meta [key: string] {
    let result = ($metadata | where key == $key | get value.0?)
    if ($result | is-empty) {
      error make {msg: $"Missing required key '($key)' in mindler/aws/config-metadata"}
    }
    $result
  }

  let mfa_serial = (get-meta "mfa_serial")
  let se_dev_role = (get-meta "se-dev-editops-role")
  let xg_dev_role = (get-meta "xg-dev-editops-role")
  let se_staging_role = (get-meta "se-staging-editops-role")
  let xg_staging_role = (get-meta "xg-staging-editops-role")

  # Generate config content
  let config = $"[profile otto.ahoniemi]
region = eu-north-1
mfa_serial = ($mfa_serial)
duration_seconds = 3600

[profile se-dev-editops]
role_arn = ($se_dev_role)
source_profile = otto.ahoniemi
region = eu-north-1
mfa_serial = ($mfa_serial)
duration_seconds = 3600

[profile xg-dev-editops]
role_arn = ($xg_dev_role)
source_profile = otto.ahoniemi
region = eu-central-1
mfa_serial = ($mfa_serial)
duration_seconds = 3600

[profile se-staging-editops]
role_arn = ($se_staging_role)
source_profile = otto.ahoniemi
region = eu-north-1
mfa_serial = ($mfa_serial)
duration_seconds = 3600

[profile xg-staging-editops]
role_arn = ($xg_staging_role)
source_profile = otto.ahoniemi
region = eu-central-1
mfa_serial = ($mfa_serial)
duration_seconds = 3600
"

  # Ensure directory exists
  mkdir ~/.aws

  # Write config
  $config | save -f ~/.aws/config

  print "AWS config generated successfully at ~/.aws/config"
}
