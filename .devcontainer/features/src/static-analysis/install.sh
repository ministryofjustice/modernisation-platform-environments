#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

logger "info" "Installing Trivy (version: ${TRIVYVERSION})"
bash "$(dirname "${0}")"/install-trivy.sh

logger "info" "Installing Checkov (version: ${CHECKOVVERSION})"
bash "$(dirname "${0}")"/install-checkov.sh
