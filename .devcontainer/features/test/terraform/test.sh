#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "tfswitch version" tfswitch --version
check "terraform version" /home/vscode/.terraform-bin/terraform -version

reportResults
