#!/usr/bin/env bash

set -euo pipefail

VERSION=${AWSSSOCLIVERSION:-"latest"}

case "$( uname -m )" in
  x86_64)
    export ARCHITECTURE="amd64" ;;
  aarch64 | armv8*)
    export ARCHITECTURE="arm64" ;;
  *)
  echo "(!) Architecture $( uname -m ) unsupported"; exit 1 ;;
esac

if [[ "${VERSION}" == "latest" ]]; then
  VERSION=$(curl --silent "https://api.github.com/repos/synfinatic/aws-sso-cli/releases/latest" | jq -r '.tag_name')
  VERSION_STRIP_V=$(echo "${VERSION}" | sed 's/v//')
fi

# Install

curl --location https://github.com/synfinatic/aws-sso-cli/releases/download/${VERSION}/aws-sso-${VERSION_STRIP_V}-linux-${ARCHITECTURE} \
  --output /usr/local/bin/aws-sso

chmod +x /usr/local/bin/aws-sso

mkdir --parents /home/vscode/.aws-sso

cp  $( dirname $0 )/src/home/vscode/.aws-sso/config.yaml /home/vscode/.aws-sso/config.yaml

chown --recursive vscode:vscode /home/vscode/.aws-sso

# Configure

echo "export AWS_SSO_FILE_PASSWORD=\"aws_sso_123456789\"" >> /home/vscode/.bashrc
