#!/bin/bash

set -euo pipefail

TF_ENV='development'
echo "Terraform apply - ${TF_ENV}"
bash scripts/terraform-init.sh terraform/environments/sprinkler
terraform -chdir="terraform/environments/sprinkler" workspace select "sprinkler-${TF_ENV}"
bash scripts/terraform-apply.sh terraform/environments/sprinkler
