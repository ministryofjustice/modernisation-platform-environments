#!/bin/bash

set -euo pipefail

dependabot_file=".github/dependabot.yml"

# Clear the dependabot file
> "$dependabot_file"

# Get a list of unique Terraform directories, excluding `.terraform` folders
tf_dirs=$(find . -type f -name '*.tf' ! -path "*/.terraform/*" | sed 's#/[^/]*$##' | sed 's|^\./||' | sort -u)

# Get a list of unique Go module directories, excluding `.terraform`
gomod_dirs=$(find . -type f -name 'go.mod' ! -path "*/.terraform/*" | sed 's#/[^/]*$##' | sed 's|^\./||' | sort -u)

echo "Writing dependabot.yml file"

cat > "$dependabot_file" << EOL
# This file is auto-generated, do not manually amend.
# https://github.com/ministryofjustice/modernisation-platform-environments/blob/main/scripts/generate-dependabot-file.sh


version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 50
  - package-ecosystem: "devcontainers"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 50
    reviewers:
      - "ministryofjustice/devcontainer-community"
EOL

# Add Terraform ecosystem entries (dynamically only for top-level directories containing .tf files)
if [[ -n "$tf_dirs" ]]; then
  echo "Generating Terraform ecosystem entry..."
  echo "  - package-ecosystem: \"terraform\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"

  # Extract only top-level directories and ensure we don't add duplicates
  echo "$tf_dirs" | awk -F/ '{print $1}' | sort -u | while IFS= read -r dir; do
    echo "      - \"$dir/**/*\"" >> "$dependabot_file"
  done
  
  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
  echo "    open-pull-requests-limit: 150" >> "$dependabot_file"
fi

# Add Go module ecosystem entries (dynamically only for top-level directories containing go.mod)
if [[ -n "$gomod_dirs" ]]; then
  echo "Generating Go module ecosystem entry..."
  echo "  - package-ecosystem: \"gomod\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"

  # Extract only top-level directories and ensure we don't add duplicates
  echo "$gomod_dirs" | awk -F/ '{print $1}' | sort -u | while IFS= read -r dir; do
    echo "      - \"$dir/**/*\"" >> "$dependabot_file"
  done

  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
  echo "    open-pull-requests-limit: 50" >> "$dependabot_file"
fi

echo "dependabot.yml has been successfully generated."
