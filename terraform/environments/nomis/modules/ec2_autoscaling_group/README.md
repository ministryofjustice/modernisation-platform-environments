# ec2-autoscaling-group module

Terraform module for standing up an auto-scale group

## Jumpserver example

As this is a windows machine this uses a user_data_raw script which has to be a base64 encoded file. This is part of the ec2-jumpserver.tf locals block.

```hcl

    ec2_jumpservers = {
      jumpserver0 = {
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

The windows user_data_raw jumpserver-user-data.yaml file gets a list of users from AWS Secrets Manager using [the AWS Get-SECSecretList](https://docs.aws.amazon.com/powershell/latest/reference/items/Get-SECSecretList.html) cmdlet. This creates a user with the password held in Secrets Manager which is put there by terraform as part of the resource in the ec2-jumpserver.tf file. A scheduled task on the EC2 jumpserver instance checks for password changes every 15 minutes as this process runs locally on each machine..

Non-Windows EC2 instances use a user_data_cloud_init variable instead which doesn't require all these steps.
