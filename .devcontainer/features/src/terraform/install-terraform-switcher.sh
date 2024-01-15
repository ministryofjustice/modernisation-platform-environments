#!/usr/bin/env bash

set -euo pipefail

TERRAFORM_SWITCHER_VERSION=${TERRAFORMSWITCHERVERSION:-"latest"}
TERRAFORM_VERSION=${TERRAFORMVERSION:-"latest"}

case "$( uname -m )" in
  x86_64)
    export ARCHITECTURE="amd64" ;;
  aarch64 | armv8*)
    export ARCHITECTURE="arm64" ;;
  *)
  echo "(!) Architecture $( uname -m ) unsupported"; exit 1 ;;
esac

if [[ "${TERRAFORM_SWITCHER_VERSION}" == "latest" ]]; then
  TERRAFORM_SWITCHER_VERSION=$(curl --silent "https://api.github.com/repos/warrensbox/terraform-switcher/releases/latest" | jq -r '.tag_name')
  TERRAFORM_SWITCHER_VERSION_STRIP_V=$(echo "${TERRAFORM_SWITCHER_VERSION}" | sed 's/v//g')
fi

if [[ "${TERRAFORM_VERSION}" == "latest" ]]; then
  TERRAFORM_VERSION=$(curl --silent "https://api.github.com/repos/hashicorp/terraform/releases/latest" | jq -r '.tag_name' | sed 's/v//g')
fi

# Install

curl --location https://github.com/warrensbox/terraform-switcher/releases/download/${TERRAFORM_SWITCHER_VERSION}/terraform-switcher_${TERRAFORM_SWITCHER_VERSION}_linux_${ARCHITECTURE}.tar.gz \
  --output terraform-switcher_${TERRAFORM_SWITCHER_VERSION}_linux_${ARCHITECTURE}.tar.gz

tar --gzip --extract --file terraform-switcher_${TERRAFORM_SWITCHER_VERSION}_linux_${ARCHITECTURE}.tar.gz

mv tfswitch /usr/local/bin/tfswitch

chmod +x /usr/local/bin/tfswitch

rm --force --recursive CHANGELOG.md LICENSE README.md terraform-switcher_${TERRAFORM_SWITCHER_VERSION}_linux_${ARCHITECTURE}.tar.gz

# Configure

mkdir --parents /home/vscode/.terraform-bin

chown --recursive vscode:vscode /home/vscode/.terraform-bin

cp $( dirname $0 )/src/home/vscode/.tfswitch.toml /home/vscode/.tfswitch.toml

chown vscode:vscode /home/vscode/.tfswitch.toml

su - vscode --command "tfswitch ${TERRAFORM_VERSION}"

echo "export PATH=\"\${PATH}:\${HOME}/.terraform-bin\"" >> /home/vscode/.bashrc

echo "complete -o nospace -C \${HOME}/.terraform-bin/terraform terraform" >> /home/vscode/.bashrc
