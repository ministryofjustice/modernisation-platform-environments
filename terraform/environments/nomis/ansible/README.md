## Introduction

EC2 instances can use ansible as part of the provisioning process and/or
in-life operational management.

## Using ansible to provision an EC2 instance

See [modules/test_instance_asg/user_data/ansible.sh.tftpl](/terraform/environments/nomis/modules/test_instance_asg/user_data/ansible.sh.tftpl)
for an example user data script for provisioning ansible.

- makes use of an ansible virtual environment installed in the base image
- clones this repo
- installs dependencies
- runs ansible against localhost
- tidies up

## Running ansible against an EC2 instance post build

A generic [site.yml](/ansible/site.yml) is provided with a dynamic inventory
[inventory_aws_ec2.yml](/ansible/inventory_aws_ec2.yml). This creates groups
based of the following tags

- business-unit
- environment-name
- application
- component
- server-type

Ansible tasks are executed on ec2 instances via AWS Session Manager, so you must have [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html#cliv2-mac-install-cmd) installed in addition to the Session Manager [plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos-signed). The target ec2 instance must also have [ssm-agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html) installed. You do not need to have an account on the remote ec2 instance in order to connect.

The `ansible_connection` variable is set to use the `community.aws.aws_ssm` plugin in [group_vars/aws_ec2.yml](/ansible/group_vars/aws_ec2.yml). The `aws_ec2` group is the default group for all instances that are obtained from dynamic inventory.

Ensure you have set your AWS credentials as environment variables or setup your `~/.aws/credentials` accordingly before attempting to run ansible. Note that at the time of writing, it does not seem possible to run Ansible with credentials obtained from `aws sso login`. Temporary credentials can be obtained from https://moj.awsapps.com/start#/

You may encounter an error similar to `ERROR! A worker was found in a dead state`. Apparently this is a Python issue and the workaround is to set an env:

```
export no_proxy='*'
```

The Session Manager plugin requires that an S3 bucket is specified as one of the connection variables. Set this within an environment specific variable, for example [group_vars/environment_name_nomis_test.yml](/terraform/environments/nomis/ansible/group_vars/environment_name_nomis_test.yml)

Define the list of roles to run on each type of server under a server-type specific variable. For example [group_vars/server_type_base.yml](/terraform/environments/nomis/ansible/group_vars/server_type_base.yml)

```
---
ansible_python_interpreter: /usr/local/bin/python3.9
roles_list:
  - get-ec2-facts
```

Run ansible

```
# Run against all hosts in check mode
ansible-playbook site.yml -i inventory_aws_ec2.yml --check

# Limit to a particular server
ansible-playbook site.yml -i inventory_aws_ec2.yml --check --limit bastion

# Limit to a particular role
ansible-playbook site.yml -i inventory_aws_ec2.yml --check --limit bastion -e "role=node-exporter"
```
