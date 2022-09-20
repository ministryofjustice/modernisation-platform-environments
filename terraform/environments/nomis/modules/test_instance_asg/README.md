Test an AMI image by using this module. Stands up an ASG using the provided
AMI image. Optionally provisions the EC2 instance using ansible.

To provision an EC2 instance using ansible:

- base image must have ansible virtual environment installed
- include `ansible_repo` variable.
- define a `server-type` tag
- a `group_vars/server_type_${server-type}.yml` must define a set of roles to install in the relevant ansible repo

For example `group_vars/server_type_base.yml` contains:

```
---
ansible_python_interpreter: /usr/local/bin/python3.9
roles_list:
  - node-exporter
```
