# ec2-autoscaling-group module

Terraform module for standing up an auto-scale group

## Jumpserver (new) example

As this is a windows machine this uses a user_data_raw script which has to be a base64 encoded file. This is part of the ec2-jumpserver.tf locals block. 

```hcl

    ec2_jumpserver_autoscaling_groups = {
      test-jumpserver-asg = {
        tags = {
          ami         = "nomis_windows_server_2022_jumpserver"
          description = "jumpserver instance"
          monitored   = false
        }
        ami_name  = "nomis_windows_server_2022_jumpserver*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
    }

```

The windows user_data_raw jumpserver-user-data.yaml file gets a list of users from AWS Secrets Manager using [the AWS Get-SECSecretList](https://docs.aws.amazon.com/powershell/latest/reference/items/Get-SECSecretList.html) cmdlet after an EMPTY secret has been created by the aws_secretsmanager_secret.jumpserver_asg resource for eash user definted in data.github_team.jumpserver. Any users that don't exist on the new EC2 instance get created with a password locally and this is posted back to the jumpserver-asg/users/<username> value where it can be retrieved later. Passwords are changed every 15 minutes as this process runs locally on each jumpserver via a windows scheduled task.

The current issue is that multiple jumpserver-asg instances will each have a different password for the same user. This is because the user_data_raw script is run on each instance and the password is generated locally. This is not ideal and needs to be fixed - See [DSOS-1584](https://dsdmoj.atlassian.net/browse/DSOS-1584)

Non-Windows EC2 instances use a user_data_cloud_init variable instead which doesn't require all these steps.
