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

For example, add following to `application_variables.tf`

```
        ANSIBLETEST = {
          always_on     = false
          ansible_repo  = "modernisation-platform-ami-builds"
          ami_name      = "nomis_rhel_7_9_baseimage_2022-09-20T09-50-42.631Z*"
          description   = "Test instance for ansible"
          instance_type = "t2.medium"
          tags = {
            server-type = "base"
            monitored   = false
          }
        }
```
