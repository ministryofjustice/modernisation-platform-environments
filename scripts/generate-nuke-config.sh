#!/bin/bash

set -euo pipefail

eval "$(jq -r '.NUKE_ACCOUNT_IDS | to_entries | .[] |"export " + .key + "=" + (.value | @sh)' <<<"$NUKE_ACCOUNT_IDS")"
cat ./scripts/nuke-config-template.txt | envsubst >./scripts/nuke-config.yml
