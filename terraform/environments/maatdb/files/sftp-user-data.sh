#!/bin/bash -xe
# Distrust eMudhra/emSign and Comodo AAA roots (AL2023 fixed ca-certificates release)
dnf update -y ca-certificates --releasever 2023.12.20261026
update-ca-trust
