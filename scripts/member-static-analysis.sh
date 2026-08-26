#!/usr/bin/env bash

# This is a convenience script for running Checkov and Trivy outside of GitHub Actions
# Run it from within the environment directory, e.g. terraform/environments/cooker

# Checkov
checkov --directory .

# Trivy
trivy config \
  --tf-exclude-downloaded-modules \
  --skip-dirs .terraform \
  --ignorefile /workspaces/modernisation-platform-environments/.trivyignore.yaml \
  .

rm -rf github_conf