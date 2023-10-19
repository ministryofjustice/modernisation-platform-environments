#!/bin/bash
set -e 
profiles=$(find . -name 'ec2-user.pub' | cut -d/ -f2)
dir=$(pwd)
(
  cd ~/.ssh
  for profile in $profiles; do
    ln -s $dir/$profile $profile
  done
)
