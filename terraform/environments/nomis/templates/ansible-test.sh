#!/bin/bash
# use when manually bodging on server

   set -e

  export PATH=/usr/local/bin:$PATH

  ansible_repo=modernisation-platform-configuration-management
  ansible_repo_basedir=ansible
  branch=main
  ansible_dir=/tmp/tmp.vWAewYuMtF

  token=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  instance_id=$(curl -sS -H "X-aws-ec2-metadata-token: $token" -v http://169.254.169.254/latest/meta-data/instance-id)
  server_type=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=server-type" --output=text | cut -f5 | sed 's/-/_/g')
  environment_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=environment-name" --output=text | cut -f5 | sed 's/-/_/g')

  # activate virtual environment
  cd $ansible_dir/python-venv
  source ansible/bin/activate

  # run ansible (comma after localhost deliberate)
  cd $ansible_dir/${ansible_repo}/${ansible_repo_basedir}
  echo "# Execute ansible"
  ansible-playbook site.yml \
   --connection=local \
   --inventory localhost, \
   --extra-vars "ansible_python_interpreter=$python" \
   --extra-vars "target=localhost" \
   --extra-vars "@group_vars/environment_name_$environment_name.yml" \
   --extra-vars "@group_vars/server_type_$server_type.yml" \
   --tags ec2provision \
   --become
