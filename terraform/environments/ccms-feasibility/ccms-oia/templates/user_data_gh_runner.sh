#!/bin/bash

# Update packages
dnf update -y

# Install dependencies
dnf install -y perl-Digest-SHA icu curl tar git git-lfs java-17-amazon-corretto java-17-amazon-corretto-devel

# eMudhra CA certificate vulnerability fix. The ec2 module ignores user_data changes, so the
# running instance isn't replaced; these were run manually on the existing box.
dnf update -y ca-certificates --releasever 2023.12.20261026
update-ca-trust

cd /home/ec2-user

# Download the runner
curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz

# Verify SHA256 checksum
echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e  actions-runner-linux-x64-2.328.0.tar.gz" | sha256sum -c -

# One runner directory per OPA rule project
mkdir -p actions-runner-means actions-runner-merits actions-runner-billing
for dir in actions-runner-means actions-runner-merits actions-runner-billing; do
  tar xzf actions-runner-linux-x64-2.328.0.tar.gz -C "$dir"
done
rm -f actions-runner-linux-x64-2.328.0.tar.gz

# Set correct permissions
chown -R ec2-user:ec2-user /home/ec2-user/actions-runner-means /home/ec2-user/actions-runner-merits /home/ec2-user/actions-runner-billing