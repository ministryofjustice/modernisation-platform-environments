# Weblogic Server

Terraform module for creating Weblogic instances in a multi-AZ autoscaling group.  

### Warm pools

Since the Weblogic instances have a very long initial start-up time, the module makes use of warm pools and lifecycle hooks.  Lifecycle hooks allow the instance to indicate to the auto-scaling group that it is ready to enter service.  This occurs once the Weblogic installation and setup script have completed (see user-data script).  At this point the instance may be either put into active service as part of the load balancer target group or moved to the warm pool, where it enters a stopped state until it is required for service by an auto-scaling event.  On exit from the warm pool the instance is started and another lifecycle hook is fired to indicate that it is in the ready state.  This lifecycle hook is activated via a cron job that runs on boot.  It does not check the state of the Weblogic service before firing, for this we instead rely on the load balancer health checks.

The number of instances in the warm pool will be equal to the max size of the auto-scaling group minus the number of active instances in the ASG.  This can be changed if desired by exposing some additional variables in the module.

As the module is currently setup, any scale down events cause active instances to be terminated.  It should be possible to instead return them to the warm pool however the Terraform AWS provider does not currently support this feature.  This behavior may be worth considering when it becomes available.  See this [issue](https://github.com/hashicorp/terraform-provider-aws/issues/23735).

 ### Scaling

 Currently there is only schedule based scaling in place, which scales the number of active instances to zero after 7pm and scales out again at 7am.  We do not scale down the maximum number of instances.  This has the affect of replacing the scaled down instances with new instances in the warm pool, thus we do not need to wait for new instances to be created at the next scale out event. 
 
 The scaling policy will need to be revisited once we move to production and scaling requirements are determined.

## Usage 

Pay particular attention to the `name` variable. This needs to be the same as the name used in the target databases internal Route 53 record, e.g. `db.<var.name>.xxxxxxxx.gov.uk`.  Alternatively we could just add a separate variable for the database name if this proves problematic.

Many variables have the `nullable` property set to false, this allows the variable default to be used if a `null` value is passed.  Handy if using the module in a `for_each` and not all values are set (see `termination_protection` in below example).

Example:
```terraform
module "weblogic" {
  source = "./modules/weblogic"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  for_each = local.application_data.accounts[local.environment].weblogics

  name = each.key

  ami_name             = each.value.ami_name
  asg_max_size         = each.value.asg_max_size
  asg_desired_capacity = each.value.asg_desired_capacity # you may prefer to just set the minimum capacity instead

  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id    = aws_security_group.weblogic_common.id
  instance_profile_policy_arn = aws_iam_policy.ec2_common_policy.arn
  key_name                    = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn  = aws_lb_listener.internal.arn

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  tags             = local.tags
  subnet_set       = local.subnet_set
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_aws.core-vpc"></a> [aws.core-vpc](#provider\_aws.core-vpc) | ~> 4.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_schedule.scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_iam_instance_profile.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_launch_template.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb_listener_rule.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_ami.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_instance_type.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_iam_policy_document.weblogic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.shared_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_file.user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | Name of AMI to be used to launch the ec2 instance | `string` | n/a | yes |
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | Owner of AMI to be used to launch the ec2 instance | `string` | `"self"` | no |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | The name of the application.  This will be name of the environment in Modernisation Platform | `string` | `"nomis"` | no |
| <a name="input_asg_desired_capacity"></a> [asg\_desired\_capacity](#input\_asg\_desired\_capacity) | The desired number of instances.  Use for manually scaling, or up the asg\_min\_size var.  Must be >= asg\_min\_size and =< asg\_max\_size. | `number` | `null` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | The maximum size of the auto scaling group | `number` | `1` | no |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | The minimum size of the auto scaling group | `number` | `1` | no |
| <a name="input_asg_warm_pool_min_size"></a> [asg\_warm\_pool\_min\_size](#input\_asg\_warm\_pool\_min\_size) | The minimum number of instances that should always be available in the auto scaling group warm pool | `number` | `0` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | This corresponds to the VPC in which the application resides | `string` | `"hmpps"` | no |
| <a name="input_common_security_group_id"></a> [common\_security\_group\_id](#input\_common\_security\_group\_id) | Common security group used by all instances | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Application environment - i.e. the terraform workspace | `string` | n/a | yes |
| <a name="input_extra_ingress_rules"></a> [extra\_ingress\_rules](#input\_extra\_ingress\_rules) | A list of extra ingress rules to be added to the instance security group | <pre>list(object({<br>    description = string<br>    from_port   = string<br>    to_port     = string<br>    protocol    = string<br>    cidr_blocks = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_instance_profile_policy_arn"></a> [instance\_profile\_policy\_arn](#input\_instance\_profile\_policy\_arn) | An IAM policy document to be attached to the weblogic instance profile | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | ec2 instance type to use for the instances | `string` | `"t2.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of ssh key resource for ec2-user | `string` | n/a | yes |
| <a name="input_load_balancer_listener_arn"></a> [load\_balancer\_listener\_arn](#input\_load\_balancer\_listener\_arn) | arn for loadbalancer fronting weblogics | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | This must be the same as the name variable used when setting up the database instance to which the weblogics will connect, e.g. CNOMT1, CNOMT2 etc | `string` | n/a | yes |
| <a name="input_oracle_app_disk_size"></a> [oracle\_app\_disk\_size](#input\_oracle\_app\_disk\_size) | Capcity of each Oracle application disk, /u01 and /u02. If not specified, the default values from the AMI block device mappings will be used. | `map(any)` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which to deploy the instances | `string` | `"eu-west-2"` | no |
| <a name="input_subnet_set"></a> [subnet\_set](#input\_subnet\_set) | Fixed variable to specify subnet-set for RAM shared subnets | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags to be applied to resources | `map(any)` | n/a | yes |
| <a name="input_termination_protection"></a> [termination\_protection](#input\_termination\_protection) | Set to true to prevent accidental deletion of instances | `bool` | `false` | no |
| <a name="input_use_default_creds"></a> [use\_default\_creds](#input\_use\_default\_creds) | Use the default weblogic admin username/password & T1 Nomis db username/password (Parameter Store Variables) | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->