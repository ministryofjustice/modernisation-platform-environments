#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

get_system_architecture

GITHUB_REPOSITORY="synfinatic/aws-sso-cli"
VERSION=${AWSSSOCLIVERSION:-"latest"}

if [[ "${VERSION}" == "latest" ]]; then
  get_github_latest_tag "${GITHUB_REPOSITORY}"
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION_STRIP_V="${VERSION#v}"
fi

curl --location https://github.com/${GITHUB_REPOSITORY}/releases/download/${VERSION}/aws-sso-${VERSION_STRIP_V}-linux-${ARCHITECTURE} \
  --output "aws-sso"

install --owner=vscode --group=vscode --mode=775 aws-sso /usr/local/bin/aws-sso

install --directory --owner=vscode --group=vscode /home/vscode/.aws-sso

install --owner=vscode --group=vscode --mode=775 "$(dirname "${0}")"/src/home/vscode/.aws-sso/config.yaml /home/vscode/.aws-sso/config.yaml

install --owner=vscode --group=vscode --mode=775 "$(dirname "${0}")"/src/home/vscode/.devcontainer/feature-completion/aws-sso.sh /home/vscode/.devcontainer/feature-completion/aws-sso.sh
