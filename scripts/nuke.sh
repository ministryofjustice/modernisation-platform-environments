#!/bin/bash

set -euo pipefail

# Parse the env variable NUKE_ACCOUNT_IDS which holds a JSON string of account IDs.
# Export the account IDs to env variables, for example: export SPRINKLER_DEVELOPMENT_ACCID=111111111111
eval "$(jq -r '.NUKE_ACCOUNT_IDS | to_entries | .[] |"export " + .key + "=" + (.value | @sh)' <<<"$NUKE_ACCOUNT_IDS")"

# Generate nuke-config.yml interpolating env variables with account IDs.
cat ./scripts/nuke-config-template.txt | envsubst >nuke-config.yml

aws sts assume-role \
  --role-arn "arn:aws:iam::${SPRINKLER_DEVELOPMENT_ACCID}:role/MemberInfrastructureAccess" \
  --role-session-name SPRINKLER_DEVELOPMENT_ACCID \
  --region eu-west-2

$HOME/bin/aws-nuke --access-key-id "$AWS_ACCESS_KEY_ID" --secret-access-key "$AWS_SECRET_ACCESS_KEY" --config nuke-config.yml
