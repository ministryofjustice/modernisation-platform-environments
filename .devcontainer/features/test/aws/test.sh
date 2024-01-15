#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aws version" aws --version
check "aws completions existence" stat /home/vscode/.devcontainer/feature-completion/aws.sh

check "aws-sso version" aws-sso version
check "aws-sso completions existence" stat /home/vscode/.devcontainer/feature-completion/aws-sso.sh
check "aws-sso configuration existence" stat /home/vscode/.aw-sso/config.yaml

reportResults
