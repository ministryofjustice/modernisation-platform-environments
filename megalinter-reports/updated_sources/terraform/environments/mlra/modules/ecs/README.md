This `ecs` local Terraform module is taken from the MP provided module - <https://github.com/ministryofjustice/modernisation-platform-terraform-ecs>, and subsequently we have developed from the code there. Below is the README.md taken form the MP module.

# Modernisation Platform ECS Cluster Module

[![repo standards badge](https://img.shields.io/badge/dynamic/json?color=blue&style=for-the-badge&logo=github&label=MoJ%20Compliant&query=%24.result&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fmodernisation-platform-terraform-ecs)](https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-github-repositories.html#modernisation-platform-terraform-ecs "Link to report")

## Usage

```hcl

module "ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs/ecs"

  subnet_set_name          = local.subnet_set_name
  vpc_all                  = local.vpc_all
  app_name                 = local.application_name
  container_instance_type  = local.app_data.accounts[local.environment].container_instance_type
  environment              = local.environment
  ami_image_id             = local.app_data.accounts[local.environment].ami_image_id
  instance_type            = local.app_data.accounts[local.environment].instance_type
  user_data                = base64encode(data.template_file.launch-template.rendered)
  key_name                 = local.app_data.accounts[local.environment].key_name
  task_definition          = data.template_file.task_definition.rendered
  ec2_desired_capacity     = local.app_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size             = local.app_data.accounts[local.environment].ec2_max_size
  ec2_min_size             = local.app_data.accounts[local.environment].ec2_min_size
  container_cpu            = local.app_data.accounts[local.environment].container_cpu
  container_memory         = local.app_data.accounts[local.environment].container_memory
  task_definition_volume   = local.app_data.accounts[local.environment].task_definition_volume
  network_mode             = local.app_data.accounts[local.environment].network_mode
  server_port              = local.app_data.accounts[local.environment].server_port
  app_count                = local.app_data.accounts[local.environment].app_count
  public_cidrs             = [data.aws_subnet.public_az_a.cidr_block, data.aws_subnet.public_az_b.cidr_block, data.aws_subnet.public_az_c.cidr_block]
  tags_common              = local.tags

  depends_on               = [aws_ecr_repository.ecr_repo, aws_lb_listener.listener]
}

```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.1 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | ~> 4.0   |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | ~> 4.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                              | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_appautoscaling_policy.scaling_policy_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy)                | resource    |
| [aws_appautoscaling_policy.scaling_policy_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy)                  | resource    |
| [aws_appautoscaling_target.scaling_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target)                     | resource    |
| [aws_autoscaling_group.cluster-scaling-group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)                      | resource    |
| [aws_cloudwatch_log_group.cloudwatch_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                     | resource    |
| [aws_cloudwatch_log_stream.cloudwatch_stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream)                  | resource    |
| [aws_ecs_capacity_provider.capacity_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider)                  | resource    |
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster)                                            | resource    |
| [aws_ecs_cluster_capacity_providers.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers)      | resource    |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)                                            | resource    |
| [aws_ecs_task_definition.linux_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)              | resource    |
| [aws_ecs_task_definition.windows_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)            | resource    |
| [aws_iam_instance_profile.ec2_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile)                 | resource    |
| [aws_iam_policy.ec2_instance_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                      | resource    |
| [aws_iam_policy.ecs_task_execution_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                             | resource    |
| [aws_iam_role.ec2_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                            | resource    |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                      | resource    |
| [aws_iam_role_policy_attachment.attach_ec2_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)        | resource    |
| [aws_iam_role_policy_attachment.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)  | resource    |
| [aws_iam_role_policy_attachment.ecs_task_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)       | resource    |
| [aws_iam_role_policy_attachment.ecs_task_secrets_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_launch_template.ec2-launch-template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template)                            | resource    |
| [aws_security_group.cluster_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                      | resource    |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition)                     | data source |
| [aws_iam_policy_document.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)             | data source |
| [aws_lb_target_group.target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_target_group)                                | data source |
| [aws_subnets.shared-private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets)                                              | data source |
| [aws_vpc.shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc)                                                              | data source |

## Inputs

| Name                                                                                                   | Description                                                                                                    | Type                                                                                                                                                                                         | Default | Required |
| ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | :------: |
| <a name="input_ami_image_id"></a> [ami_image_id](#input_ami_image_id)                                  | EC2 AMI image to run in the ECS cluster                                                                        | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_app_count"></a> [app_count](#input_app_count)                                           | Number of docker containers to run                                                                             | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_app_name"></a> [app_name](#input_app_name)                                              | Name of the application                                                                                        | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_appscaling_max_capacity"></a> [appscaling_max_capacity](#input_appscaling_max_capacity) | Maximum capacity of the application scaling target                                                             | `number`                                                                                                                                                                                     | `3`     |    no    |
| <a name="input_appscaling_min_capacity"></a> [appscaling_min_capacity](#input_appscaling_min_capacity) | Minimum capacity of the application scaling target                                                             | `number`                                                                                                                                                                                     | `1`     |    no    |
| <a name="input_container_cpu"></a> [container_cpu](#input_container_cpu)                               | Container instance CPU units to provision (1 vCPU = 1024 CPU units)                                            | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_container_instance_type"></a> [container_instance_type](#input_container_instance_type) | Container OS being used (windows or linux)                                                                     | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_container_memory"></a> [container_memory](#input_container_memory)                      | Container instance memory to provision (in MiB)                                                                | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_ec2_desired_capacity"></a> [ec2_desired_capacity](#input_ec2_desired_capacity)          | Number of EC2s in the cluster                                                                                  | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_ec2_egress_rules"></a> [ec2_egress_rules](#input_ec2_egress_rules)                      | Security group egress rules for the cluster EC2s                                                               | <pre>map(object({<br> description = string<br> from_port = number<br> to_port = number<br> protocol = string<br> security_groups = list(string)<br> cidr_blocks = list(string)<br> }))</pre> | n/a     |   yes    |
| <a name="input_ec2_ingress_rules"></a> [ec2_ingress_rules](#input_ec2_ingress_rules)                   | Security group ingress rules for the cluster EC2s                                                              | <pre>map(object({<br> description = string<br> from_port = number<br> to_port = number<br> protocol = string<br> security_groups = list(string)<br> cidr_blocks = list(string)<br> }))</pre> | n/a     |   yes    |
| <a name="input_ec2_max_size"></a> [ec2_max_size](#input_ec2_max_size)                                  | Max Number of EC2s in the cluster                                                                              | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_ec2_min_size"></a> [ec2_min_size](#input_ec2_min_size)                                  | Min Number of EC2s in the cluster                                                                              | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_instance_type"></a> [instance_type](#input_instance_type)                               | EC2 instance type to run in the ECS cluster                                                                    | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_key_name"></a> [key_name](#input_key_name)                                              | Key to access EC2s in ECS cluster                                                                              | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_lb_tg_name"></a> [lb_tg_name](#input_lb_tg_name)                                        | Load balancer target group name used by ECS service                                                            | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_network_mode"></a> [network_mode](#input_network_mode)                                  | The network mode used for the containers in the task. If OS used is Windows network_mode must equal none.      | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_server_port"></a> [server_port](#input_server_port)                                     | The port the containers will be listening on                                                                   | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_subnet_set_name"></a> [subnet_set_name](#input_subnet_set_name)                         | The name of the subnet set associated with the account                                                         | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_tags_common"></a> [tags_common](#input_tags_common)                                     | Common tags to be used by all resources                                                                        | `map(string)`                                                                                                                                                                                | n/a     |   yes    |
| <a name="input_task_definition"></a> [task_definition](#input_task_definition)                         | Task definition to be used by the ECS service                                                                  | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_task_definition_volume"></a> [task_definition_volume](#input_task_definition_volume)    | Name of the volume referenced in the sourceVolume parameter of container definition in the mountPoints section | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_user_data"></a> [user_data](#input_user_data)                                           | The configuration used when creating EC2s used for the ECS cluster                                             | `string`                                                                                                                                                                                     | n/a     |   yes    |
| <a name="input_vpc_all"></a> [vpc_all](#input_vpc_all)                                                 | The full name of the VPC (including environment) used to create resources                                      | `string`                                                                                                                                                                                     | n/a     |   yes    |

## Outputs

| Name                                                                                                                       | Description                                                 |
| -------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| <a name="output_app_scale_down_policy_arn"></a> [app_scale_down_policy_arn](#output_app_scale_down_policy_arn)             | ARN for app autoscaling - scaling policy down               |
| <a name="output_app_scale_up_policy_arn"></a> [app_scale_up_policy_arn](#output_app_scale_up_policy_arn)                   | ARN for app autoscaling - scaling policy up                 |
| <a name="output_cluster_ec2_security_group_id"></a> [cluster_ec2_security_group_id](#output_cluster_ec2_security_group_id) | Security group id of EC2s used for ECS cluster              |
| <a name="output_current_task_definition"></a> [current_task_definition](#output_current_task_definition)                   | Displays task definition information and version being used |
| <a name="output_ec2_autoscaling_group"></a> [ec2_autoscaling_group](#output_ec2_autoscaling_group)                         | Autoscaling group information                               |
| <a name="output_ecs_service"></a> [ecs_service](#output_ecs_service)                                                       | Displays task definition information and version being used |
| <a name="output_ecs_task_execution_policy"></a> [ecs_task_execution_policy](#output_ecs_task_execution_policy)             | Displays task definition policy details                     |
| <a name="output_ecs_task_execution_role"></a> [ecs_task_execution_role](#output_ecs_task_execution_role)                   | Displays task definition role details                       |

<!-- END_TF_DOCS -->

## Looking for issues?

If you're looking to raise an issue with this module, please create a new issue in the [Modernisation Platform repository](https://github.com/ministryofjustice/modernisation-platform/issues).
