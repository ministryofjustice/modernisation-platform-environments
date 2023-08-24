#!/bin/bash
app=$1
if [[ -z $app ]]; then
  echo "Usage: $0 <application>"
  echo "e.g. $0 nomis"
  exit 1
fi
envs="development test preproduction production"
for env in $envs; do  
  mkdir -p ${app}-${env}
  cd ${app}-${env}
  echo "Creating key for ${app}-${env}"
  echo "NOTE: set empty passphrase by pressing RETURN when prompted"
  echo "----"
  ssh-keygen -m pem -t rsa -b 4096 -f ec2-user
  cd - > /dev/null
done

