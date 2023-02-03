# `ec2_autoscaling_group` module

Terraform module for standing up ec2 autoscaling group resources:

- launch template
- autoscaling group
- optional autoscaling group schedules, e.g. for reducing desired count out of hours
- optional ssm parameters
- iam role and policy
- optional load balancer target group

The launch template is defined by the instance variable which follows the
`aws_ec2_instance` resource parameters. So you can easily swap between using
this `ec2_autoscaling_group` module and the `ec2_instance` module.

See `environments/nomis` for usage examples.
