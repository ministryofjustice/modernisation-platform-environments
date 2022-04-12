#!/bin/bash

set -euo pipefail

./scripts/generate-nuke-config.sh

TF_ENV='development'
bash scripts/terraform-init.sh terraform/environments/sprinkler
terraform -chdir="terraform/environments/sprinkler" workspace select "sprinkler-${TF_ENV}"
$HOME/bin/aws-nuke --access-key-id "$AWS_ACCESS_KEY_ID" --secret-access-key "$AWS_SECRET_ACCESS_KEY" --config nuke-config.yml
