#!/bin/bash

# Update packages
dnf update -y

# Install dependencies
dnf install -y perl-Digest-SHA icu curl tar

# Create directory for GitHub Actions runner
mkdir -p /home/ec2-user/actions-runner
cd /home/ec2-user/actions-runner

# Download the runner
curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz

# Verify SHA256 checksum
echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e  actions-runner-linux-x64-2.328.0.tar.gz" | sha256sum -c -

# Extract runner
tar xzf actions-runner-linux-x64-2.328.0.tar.gz

# Set correct permissions
chown -R ec2-user:ec2-user /home/ec2-user/actions-runner

# Install Git

dnf install -y git git-lfs

# # Install Git LFS
# git lfs install --system

# Install Java
dnf install -y java-17-amazon-corretto java-17-amazon-corretto-devel
