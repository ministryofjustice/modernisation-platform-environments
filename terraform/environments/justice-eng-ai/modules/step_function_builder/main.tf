data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  ec2_mode = try(var.script_runner.launch_type, "FARGATE") == "EC2"

  script_runner_steps = [for step in var.steps : step if step.type == "script_runner"]
  step_function_steps = [for step in var.steps : step if step.type == "step_function"]

  transitions = {
    for index, step in var.steps : step.name => index < length(var.steps) - 1 ? {
      Next = local.ec2_mode && var.steps[index + 1].type == "script_runner" ? "${var.steps[index + 1].name}_prepare_host" : var.steps[index + 1].name
      } : {
      End = true
    }
  }

  script_runner_states = {
    for step in local.script_runner_steps : step.name => merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::ecs:runTask.sync"
        Parameters = merge({
          LaunchType     = var.script_runner.launch_type
          Cluster        = var.script_runner.cluster_arn
          TaskDefinition = var.script_runner.task_definition_family
          Overrides = {
            ContainerOverrides = [{
              Name = var.script_runner.container_name
              Environment = concat(
                [
                  { Name = "SCRIPT_PATH", Value = step.script_path },
                  { Name = "SCRIPT_RUNTIME", Value = step.shell_type },
                ],
                [
                  for variable in try(step.variables, []) : merge(
                    { Name = variable.name },
                    try(variable.path, null) == null ? { Value = variable.value } : { "Value.$" = variable.path }
                  )
                ],
              )
            }]
          }
          },
          !local.ec2_mode ? {} : {
            Count = 1
            PlacementConstraints = [{
              Type           = "memberOf"
              "Expression.$" = "States.Format('ec2InstanceId == {}', $.script_runner_host.instance.instance_id)"
            }]
          },
          # Host-network EC2 tasks cannot take an awsvpc network configuration.
          var.script_runner.launch_type != "FARGATE" ? {} : {
            NetworkConfiguration = {
              AwsvpcConfiguration = {
                Subnets        = var.script_runner.subnets
                SecurityGroups = var.script_runner.security_groups
                AssignPublicIp = var.script_runner.assign_public_ip
              }
            }
        })
      },
      !local.ec2_mode ? local.transitions[step.name] : {
        Next       = "${step.name}_check_exit_code"
        ResultPath = "$.script_runner_host.task_result"
        Catch      = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.failure", Next = "${step.name}_terminate_instance" }]
      },
      local.ec2_mode ? { TimeoutSeconds = try(step.timeout_seconds, 3600) } : try(step.timeout_seconds, null) == null ? {} : { TimeoutSeconds = step.timeout_seconds },
      local.ec2_mode || try(step.result_path, null) == null ? {} : { ResultPath = step.result_path },
      length(try(step.retry, [])) > 0 ? { Retry = step.retry } : !local.ec2_mode ? {} : {
        Retry                                   = [{ ErrorEquals = ["AmazonECS.Unknown"], IntervalSeconds = 15, BackoffRate = 2, MaxAttempts = 3 }]
      }
    )
  }

  step_function_states = {
    for step in local.step_function_steps : step.name => merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::states:startExecution.sync:2"
        Parameters = {
          StateMachineArn = "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${step.state_machine_name}"
          "Input.$"       = try(step.input_path, "$")
        }
      },
      local.transitions[step.name],
      try(step.timeout_seconds, null) == null ? {} : { TimeoutSeconds = step.timeout_seconds },
      try(step.result_path, null) == null ? {} : { ResultPath = step.result_path },
      length(try(step.retry, [])) == 0 ? {} : { Retry = step.retry }
    )
  }

  definition = {
    Comment = "Runs an ordered process using ECS script runner tasks and nested Step Functions."
    StartAt = local.ec2_mode && var.steps[0].type == "script_runner" ? "${var.steps[0].name}_prepare_host" : var.steps[0].name
    States  = merge(local.script_runner_states, local.step_function_states, local.disposable_lifecycle_states)
  }

}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_sfn_state_machine" "this" {
  name       = var.name
  role_arn   = var.execution_role_arn
  type       = "STANDARD"
  definition = jsonencode(local.definition)
  tags       = var.tags

  depends_on = [aws_cloudwatch_log_group.this, aws_sfn_state_machine.disposable_expiry]

  lifecycle {
    precondition {
      condition     = local.ec2_mode ? var.ec2 != null : var.ec2 == null
      error_message = "EC2 mode requires ec2 host settings. FARGATE mode must not supply ec2 host settings."
    }

    precondition {
      condition = var.ec2 == null ? true : alltrue([
        for step in local.script_runner_steps : var.ec2.max_lifetime_seconds >
        (var.ec2.registration_attempts + 1) * 30 + try(step.timeout_seconds, 3600) + 600
      ])
      error_message = "The instance lifetime must exceed registration polling plus each task timeout and a 600-second cleanup margin."
    }
  }

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.this.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }
}