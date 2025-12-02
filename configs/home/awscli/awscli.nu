def --env acp [
  profile?: string    # AWS profile to switch to (empty to clear)
  mfa_token?: string  # MFA token (will prompt if needed)
] {
  # Clear credentials if no profile specified
  if ($profile | is-empty) {
    $env.AWS_DEFAULT_PROFILE = null
    $env.AWS_PROFILE = null
    $env.AWS_EB_PROFILE = null
    $env.AWS_ACCESS_KEY_ID = null
    $env.AWS_SECRET_ACCESS_KEY = null
    $env.AWS_SESSION_TOKEN = null
    print "AWS profile cleared."
    return
  }

  # Get available profiles and validate
  let config_file = $env.AWS_CONFIG_FILE? | default $"($env.HOME)/.aws/config"
  let available_profiles = try {
    ^aws configure list-profiles | lines
  } catch {
    error make {msg: $"Failed to read AWS profiles from ($config_file)"}
  }

  if ($profile not-in $available_profiles) {
    error make {
      msg: $"Profile '($profile)' not found in ($config_file)\nAvailable profiles: ($available_profiles | str join ', ')"
    }
  }

  # Get source profile for credential lookup
  # For role profiles, get the source_profile; for base profiles, use the profile itself
  let source_profile = try { ^aws configure get source_profile --profile $profile | str trim } catch { $profile }

  # Get fallback credentials from password-store using source profile
  let fallback_creds = try {
    ^pass show mindler/aws/($source_profile) | lines
  } catch {
    []
  }

  let fallback_access_key = if ($fallback_creds | length) >= 1 { $fallback_creds.0 | str trim } else { "" }
  let fallback_secret_key = if ($fallback_creds | length) >= 2 { $fallback_creds.1 | str trim } else { "" }
  let fallback_session_token = ""  # Never stored, only obtained via STS

  mut aws_access_key_id = $fallback_access_key
  mut aws_secret_access_key = $fallback_secret_key
  mut aws_session_token = $fallback_session_token

  # Check for MFA configuration
  let mfa_serial = try { ^aws configure get mfa_serial --profile $profile | str trim } catch { "" }
  let duration_seconds = try { ^aws configure get duration_seconds --profile $profile | str trim } catch { "" }

  mut mfa_opts = []
  mut token = $mfa_token

  if ($mfa_serial | is-not-empty) {
    # Get MFA token from password-store if not provided
    if ($token | is-empty) {
      $token = try {
        ^pass otp mindler/aws/cli-mfa | str trim
      } catch {|err|
        error make {
          msg: $"Failed to retrieve MFA token from password-store: ($err.msg)\nMake sure 'pass otp mindler/aws/cli-mfa' works"
        }
      }
    }

    $mfa_opts = [
      --serial-number $mfa_serial
      --token-code $token
      --duration-seconds $duration_seconds
    ]
  }

  # Check if we need to assume a role
  let role_arn = try { ^aws configure get role_arn --profile $profile | str trim } catch { "" }
  let sess_name = try { ^aws configure get role_session_name --profile $profile | str trim } catch { "" }

  mut aws_command = []

  if ($role_arn | is-not-empty) {
    # Assume role
    $aws_command = [aws sts assume-role --role-arn $role_arn]
    $aws_command = ($aws_command | append $mfa_opts)

    # Check for external ID
    let external_id = try { ^aws configure get external_id --profile $profile | str trim } catch { "" }
    if ($external_id | is-not-empty) {
      $aws_command = ($aws_command | append [--external-id $external_id])
    }

    # Get session name
    let session_name = if ($sess_name | is-not-empty) { $sess_name } else { $source_profile }

    $aws_command = ($aws_command | append [
      --role-session-name $session_name
    ])

    print $"Assuming role ($role_arn) using profile ($source_profile)"
  } else {
    # Just get session token with MFA
    $aws_command = [aws sts get-session-token]
    $aws_command = ($aws_command | append $mfa_opts)
    print $"Obtaining session token for profile ($profile)"
  }

  # Add output format
  $aws_command = ($aws_command | append [
    --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]'
    --output text
  ])

  # Store command as immutable for closure capture
  let final_command = $aws_command

  # Execute AWS command and get credentials
  # Set credentials in environment for AWS CLI to use
  let credentials_result = try {
    with-env {
      AWS_ACCESS_KEY_ID: $fallback_access_key,
      AWS_SECRET_ACCESS_KEY: $fallback_secret_key
    } {
      ^$final_command.0 ...($final_command | skip 1) | complete
    }
  } catch {|err|
    error make {msg: $"AWS command failed: ($err.msg)"}
  }

  if $credentials_result.exit_code != 0 {
    error make {msg: $"AWS command failed: ($credentials_result.stderr)"}
  }

  # Parse credentials from tab-separated output
  let credentials = $credentials_result.stdout | str trim | split row "\t"
  if ($credentials | length) == 3 {
    $aws_access_key_id = $credentials.0
    $aws_secret_access_key = $credentials.1
    $aws_session_token = $credentials.2
  }

  # Export credentials to environment
  if ($aws_access_key_id | is-not-empty) and ($aws_secret_access_key | is-not-empty) {
    $env.AWS_DEFAULT_PROFILE = $profile
    $env.AWS_PROFILE = $profile
    $env.AWS_EB_PROFILE = $profile
    $env.AWS_ACCESS_KEY_ID = $aws_access_key_id
    $env.AWS_SECRET_ACCESS_KEY = $aws_secret_access_key

    if ($aws_session_token | is-not-empty) {
      $env.AWS_SESSION_TOKEN = $aws_session_token
    } else {
      $env.AWS_SESSION_TOKEN = null
    }

    print $"Switched to AWS Profile: ($profile)"
  } else {
    error make {msg: "Failed to obtain AWS credentials"}
  }
}
