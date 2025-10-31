# Fargate Patching/Retirement graceful replacement module

## Description

This module allows users to automate the graceful replacement of Fargate tasks in an ECS cluster when AWS
sends a health event for AWS_ECS_TASK_PATCHING_RETIREMENT.

Usually these come in the form of an email notification from AWS and the result is that tasks are
terminated and replaced with new tasks approximately 7 days after receiving the notification.

The issue with this is that the tasks are terminated without any warning and even though it respects the service
minimum and maximum, it can cause issues with the service if the tasks are not replaced gracefully.

This module automates the restart process at a time of your choosing, allowing you schedule the restarts outside of
business hours.

It creates an eventbridge rule with triggers a step function state machine when the event is received.
The state machine calls a lambda which calulates next occurance of the restart time
and then uses the wait state to wait until that time before calling another lambda to perform the AWS
reccomended steps to gracefully replace the tasks.

This is functionally equivalent to the manual steps outlined in the AWS documentation here:
<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/prepare-task-retirement.html#prepare-task-retirement-change-time>

## Usage

```hcl
module "fargate_graceful_retirement" {
  source = "../../../../modules/fargate_graceful_retirement"
  restart_time = "02:00" # Time in 24 hour format eg 2AM
  restart_day_of_the_week = "THURSDAY" # Day of the week to restart the tasks
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ecs_restart_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.step_function_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.lambda_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.step_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.step_function_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.calculate_wait_time](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.ecs_restart_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sfn_state_machine.ecs_restart_state_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |
| [archive_file.lambda_function_calculate_wait_time_payload](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_function_ecs_restart_payload](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.lambda_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_debug_logging"></a> [debug\_logging](#input\_debug\_logging) | Enable debug logging | `bool` | `false` | no |
| <a name="input_restart_day_of_the_week"></a> [restart\_day\_of\_the\_week](#input\_restart\_day\_of\_the\_week) | The day of the week to restart the ECS task | `string` | `"WEDNESDAY"` | no |
| <a name="input_restart_time"></a> [restart\_time](#input\_restart\_time) | The time at which to restart the ECS task | `string` | `"22:00"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
