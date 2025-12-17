def aws-profiles-completer [] {
  ^aws configure list-profiles | lines
}

def get-aws-config [profile: string, key: string] {
  ^aws configure get $key --profile $profile | str trim
}

def --env acp [
  profile?: string@aws-profiles-completer
] {
  if ($profile | is-empty) {
    [AWS_DEFAULT_PROFILE AWS_PROFILE AWS_EB_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN]
    | each { hide-env -i $in }
    print "AWS profile cleared."
    return
  }

  let source_profile = try { get-aws-config $profile source_profile } catch { $profile }
  let source_creds = ^pass show $"aws/($source_profile)" | lines | each { str trim }
  let mfa_token = ^pass otp aws/cli-mfa | str trim
  let role_arn = get-aws-config $profile role_arn
  let mfa_serial = get-aws-config $source_profile mfa_serial
  let duration_seconds = get-aws-config $source_profile duration_seconds

  print $"Assuming role ($role_arn) using profile ($source_profile)"

  let creds = with-env {
    AWS_ACCESS_KEY_ID: $source_creds.0,
    AWS_SECRET_ACCESS_KEY: $source_creds.1
  } {
    (^aws sts assume-role
      --role-arn $role_arn
      --serial-number $mfa_serial
      --token-code $mfa_token
      --duration-seconds $duration_seconds
      --role-session-name $source_profile
      --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]'
      --output text)
  } | split row "\t"

  $env.AWS_DEFAULT_PROFILE = $profile
  $env.AWS_PROFILE = $profile
  $env.AWS_EB_PROFILE = $profile
  $env.AWS_ACCESS_KEY_ID = $creds.0
  $env.AWS_SECRET_ACCESS_KEY = $creds.1
  $env.AWS_SESSION_TOKEN = $creds.2

  print $"Switched to AWS profile: ($profile)"
}
