#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "aws version" aws --version
check "aws-sso version" aws-sso version

reportResults
