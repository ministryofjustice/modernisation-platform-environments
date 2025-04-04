#!/bin/bash

set -euo pipefail

dependabot_file=".github/dependabot.yml"

# Clear the dependabot file
> "$dependabot_file"

# Get a list of unique Terraform directories, excluding `.terraform` folders
all_tf_folders=$(find . -type f -name '*.tf' ! -path "*/.terraform/*" | sed 's#/[^/]*$##' | sed 's|^\./||' | sort -u)

echo
echo "Filtered Terraform folders:"
printf '%s\n' "$all_tf_folders"

echo "Writing dependabot.yml file"
cat > "$dependabot_file" << EOL
# This file is auto-generated, do not manually amend.
# scripts/generate-dependabot.sh

version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
  - package-ecosystem: "devcontainers"
    directory: "/"
    schedule:
      interval: "daily"
    reviewers:
      - "ministryofjustice/devcontainer-community"
  - package-ecosystem: "terraform"
    directories:
EOL

# Append Terraform directories with correct YAML indentation
while IFS= read -r folder; do
  echo "    - \"/$folder\"" >> "$dependabot_file"
done <<< "$all_tf_folders"

cat >> "$dependabot_file" << EOL
    schedule:
      interval: "daily"
EOL

echo "dependabot.yml has been generated successfully."
