#!/bin/bash

set -euo pipefail

dependabot_file=.github/dependabot.yml

# Clear the dependabot file
> $dependabot_file

# Get a list of Terraform folders
all_tf_folders=`find . -type f -name '*.tf' | sed 's#/[^/]*$##' | sed 's/.\///'| sort | uniq`
echo
echo "All TF folders"
echo $all_tf_folders

echo "Writing dependabot.yml file"
# Creates a dependabot file to avoid having to manually add each new TF folder
# Add any additional fixed entries in this top section
  cat > $dependabot_file << EOL
# This file is auto-generated here, do not manually amend.
# scripts/generate-dependabot.sh

version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
EOL

echo "Generating entry for Terraform ecosystem"
echo "  - package-ecosystem: \"terraform\"" >> $dependabot_file
echo "    directories:" >> $dependabot_file
for folder in $all_tf_folders; do
  echo "      - \"/$folder\"" >> $dependabot_file
done
echo "    schedule:" >> $dependabot_file
echo "      interval: \"daily\"" >> $dependabot_file