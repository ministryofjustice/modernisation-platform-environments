#!/usr/bin/env bash

set -euo pipefail

VERSION=${AWSCLIVERSION:-"latest"}

if [[ "${VERSION}" == "latest" ]]; then
  ARTEFACT="awscli-exe-linux-$( uname -m ).zip"
else
  ARTEFACT="awscli-exe-linux-$( uname -m )-${VERSION}.zip"
fi

# Install

apt-get update --yes

apt-get -y install --no-install-recommends \
  ca-certificates \
  curl \
  unzip

curl https://awscli.amazonaws.com/${ARTEFACT} \
  --output ${ARTEFACT}

unzip ${ARTEFACT}

bash ./aws/install

rm --force --recursive aws ${ARTEFACT}

# Configure

echo "complete -C '/usr/local/bin/aws_completer' aws" >> /home/vscode/.bashrc

# Cleanup

rm --force --recursive /var/lib/apt/lists/*
