#!/usr/bin/env bash

set -e

source /usr/local/bin/devcontainer-utils

VERSION=${CHECKOVVERSION:-"latest"}
GITHUB_REPOSITORY="bridgecrewio/checkov"

if [ "${VERSION}" == "latest" ]; then
  get_github_latest_tag ${GITHUB_REPOSITORY}
  VERSION="${GITHUB_LATEST_TAG}"
  VERSION_STRIP_V="${GITHUB_LATEST_TAG_STRIP_V}"
else
  VERSION="${VERSION}"
fi

pip_install "checkov==${VERSION}"
