#!/usr/bin/env bash

# Credential helper for aws cli. Supports mfa and role assuming.
# Sessions are cached to gpg-ecnrypted json files.
#
# tool requirements: awscli, jq, pass (with otp extension), gpg
#
# for simple usecase with role assuming profile "my-profile" and base account "base-account":
# 1. add a pass entry "aws/base-account" with following fields:
#   - line 1: access key id
#   - line 2: secret access key
#   - line starting with otpauth:// (or other supported otp url)
# 2. define your config in .aws/config as follows:
#   [profile my-profile]
#   credential_process = aws-creds my-profile
#   x_source_profile = base-account
#   x_role_arn = arn:aws:iam::123456789:role/MyRole
#
#   [profile base-account]
#   mfa_serial = arn:aws:iam::123456789:mfa/user
#   duration_seconds = 3600
# 3. put this script in your path

set -euo pipefail

# helper function to read values
aws_config_get() {
  aws configure get "$1" --profile "$2" 2>/dev/null || true
}

# validate profile
PROFILE="${1:?Usage: aws-creds <profile>}"
if ! aws configure list-profiles 2>/dev/null | grep -qx "$PROFILE"; then
  echo "Profile '$PROFILE' not found in AWS config" >&2
  exit 1
fi

# define and create cache if it doesn't exist
SESSION_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/aws-sessions"
SESSION_CACHE="${SESSION_CACHE_DIR}/${PROFILE}.json.gpg"
mkdir -p "$SESSION_CACHE_DIR"

# check existing cache
if [[ -f $SESSION_CACHE ]] && cached=$(gpg -d "$SESSION_CACHE" 2>/dev/null); then
  expires_in=$(echo "$cached" | jq -r '(.Expiration | sub("\\+00:00$"; "Z") | fromdateiso8601) - now' 2>/dev/null || echo 0) # writing in utc to avoid timezone conflicts. output from aws not fully iso8601 compliant so some data mangling needed
  if ((${expires_in%.*} > 60)); then
    echo "$cached" # echo for awscli
    exit 0
  fi
fi

# read config
SOURCE_PROFILE=$(aws_config_get x_source_profile "$PROFILE")
ROLE_ARN=$(aws_config_get x_role_arn "$PROFILE")
DURATION=$(aws_config_get duration_seconds "$SOURCE_PROFILE")
MFA_SERIAL=$(aws_config_get mfa_serial "$SOURCE_PROFILE")

if [[ -z $SOURCE_PROFILE || -z $ROLE_ARN || -z $DURATION || -z $MFA_SERIAL ]]; then
  echo "Missing x_source_profile, x_role_arn, duration or mfa_serial in config" >&2
  exit 1
fi

# Creds from pass
PASS_PATH="aws/${SOURCE_PROFILE}"
AWS_ACCESS_KEY_ID=$(pass show "$PASS_PATH" | sed -n '1p')
AWS_SECRET_ACCESS_KEY=$(pass show "$PASS_PATH" | sed -n '2p')

# TOTP from pass-otp
TOKEN=$(pass otp "$PASS_PATH")

# Assume role
creds=$(AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "${PROFILE}-session" \
  --serial-number "$MFA_SERIAL" \
  --token-code "$TOKEN" \
  --duration-seconds "$DURATION" \
  --output json)

# form output
output=$(jq -n \
  --argjson creds "$creds" \
  '{
    Version: 1,
    AccessKeyId: $creds.Credentials.AccessKeyId,
    SecretAccessKey: $creds.Credentials.SecretAccessKey,
    SessionToken: $creds.Credentials.SessionToken,
    Expiration: $creds.Credentials.Expiration
  }')

# cache output to session cache
echo "$output" | gpg --yes -e --default-recipient-self -o "$SESSION_CACHE"

# echo for awscli
echo "$output"
