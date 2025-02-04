# AWS Aurora Terraform module

Terraform module which creates RDS aurora resources on AWS.

Taken from <https://github.com/terraform-aws-modules/terraform-aws-rds-aurora>

Version using version.txt file for now, we will move to remote modules and git refs later

## Scheduler ##

Creates a lambda function that uses tags to start and stop the cluster.

