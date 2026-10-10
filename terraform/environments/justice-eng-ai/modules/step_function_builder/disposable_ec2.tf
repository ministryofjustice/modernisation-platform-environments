locals {
  disposable_steps       = local.ec2_mode && var.ec2 != null ? local.script_runner_steps : []
  disposable_expiry_name = "${substr(var.name, 0, 64)}-expire-instance"
  disposable_api_retry = [{
    ErrorEquals     = ["States.TaskFailed"]
    IntervalSeconds = 5
    BackoffRate     = 2
    MaxAttempts     = 5
  }]

  disposable_contexts = merge(
    { for step in local.disposable_steps : step.name => {
      result_path = coalesce(try(step.result_path, null), "$")
      next_state  = try(local.transitions[step.name].Next, null)
      watchdog    = false
    } },
    !local.ec2_mode || var.ec2 == null ? {} : {
      __expiry = { result_path = "$", next_state = null, watchdog = true }
    },
  )

  disposable_cleanup_states = {
    for name, context in local.disposable_contexts : name => {
      "${name}_terminate_instance" = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:terminateInstances"
        Parameters = {
          "InstanceIds.$" = "States.Array($.script_runner_host.instance.instance_id)"
        }
        ResultPath = null
        Retry      = local.disposable_api_retry
        Catch      = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.cleanup_failure", Next = "${name}_cleanup_failed" }]
        Next       = "${name}_initialise_termination_poll"
      }
      "${name}_initialise_termination_poll" = {
        Type       = "Pass"
        Result     = { attempts = 0 }
        ResultPath = "$.script_runner_host.termination_poll"
        Next       = "${name}_wait_for_termination"
      }
      "${name}_wait_for_termination" = {
        Type    = "Wait"
        Seconds = 10
        Next    = "${name}_describe_instance"
      }
      "${name}_describe_instance" = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:describeInstances"
        Parameters = {
          "InstanceIds.$" = "States.Array($.script_runner_host.instance.instance_id)"
        }
        ResultSelector = { "state.$" = "$.Reservations[0].Instances[0].State.Name" }
        ResultPath     = "$.script_runner_host.termination_state"
        Retry          = local.disposable_api_retry
        Catch          = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.cleanup_failure", Next = "${name}_cleanup_failed" }]
        Next           = "${name}_check_terminated"
      }
      "${name}_check_terminated" = {
        Type = "Choice"
        Choices = [
          { Variable = "$.script_runner_host.termination_state.state", StringEquals = "terminated", Next = "${name}_check_registration" },
          { Variable = "$.script_runner_host.termination_poll.attempts", NumericGreaterThanEquals = 30, Next = "${name}_termination_timed_out" },
        ]
        Default = "${name}_increment_termination_poll"
      }
      "${name}_increment_termination_poll" = {
        Type       = "Pass"
        Parameters = { "attempts.$" = "States.MathAdd($.script_runner_host.termination_poll.attempts, 1)" }
        ResultPath = "$.script_runner_host.termination_poll"
        Next       = "${name}_wait_for_termination"
      }
      "${name}_check_registration" = {
        Type    = "Choice"
        Choices = [{ Variable = "$.script_runner_host.registration.container_arns[0]", IsPresent = true, Next = "${name}_deregister_instance" }]
        Default = "${name}_check_failure"
      }
      "${name}_deregister_instance" = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ecs:deregisterContainerInstance"
        Parameters = {
          Cluster               = var.script_runner.cluster_arn
          "ContainerInstance.$" = "$.script_runner_host.registration.container_arns[0]"
          Force                 = true
        }
        ResultPath = null
        Retry      = local.disposable_api_retry
        Catch      = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.cleanup_failure", Next = "${name}_cleanup_failed" }]
        Next       = "${name}_check_failure"
      }
      "${name}_check_failure" = {
        Type    = "Choice"
        Choices = [{ Variable = "$.script_runner_host.failure", IsPresent = true, Next = "${name}_failed" }]
        Default = "${name}_finish"
      }
      "${name}_failed" = {
        Type      = "Fail"
        ErrorPath = "$.script_runner_host.failure.Error"
        CausePath = "$.script_runner_host.failure.Cause"
      }
      "${name}_cleanup_failed" = {
        Type      = "Fail"
        ErrorPath = "$.script_runner_host.cleanup_failure.Error"
        CausePath = "$.script_runner_host.cleanup_failure.Cause"
      }
      "${name}_termination_timed_out" = {
        Type  = "Fail"
        Error = "InstanceTerminationTimeout"
        Cause = "The dedicated instance did not terminate within the cleanup polling limit."
      }
      "${name}_finish" = merge(
        context.watchdog ? { Type = "Succeed" } : {
          Type                    = "Pass"
          InputPath               = "$.script_runner_host.task_result"
          ResultPath              = context.result_path
        },
        context.watchdog ? {} : context.next_state == null ? { End = true } : { Next = context.next_state },
      )
    }
  }

  disposable_lifecycle_states = merge({}, [for step in local.disposable_steps : merge(
    local.disposable_cleanup_states[step.name],
    {
      "${step.name}_prepare_host" = {
        Type = "Pass"
        Parameters = {
          "client_token.$" = "States.UUID()"
          poll             = { attempts = 0 }
        }
        ResultPath = "$.script_runner_host"
        Next       = "${step.name}_start_expiry"
      }
      "${step.name}_start_expiry" = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::states:startExecution"
        Parameters = {
          StateMachineArn = "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.disposable_expiry_name}"
          "Name.$"        = "$.script_runner_host.client_token"
          Input = {
            "client_token.$"  = "$.script_runner_host.client_token"
            "execution_arn.$" = "$$.Execution.Id"
          }
        }
        ResultPath = null
        Retry      = local.disposable_api_retry
        Next       = "${step.name}_launch_instance"
      }
      "${step.name}_launch_instance" = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:runInstances"
        Parameters = {
          LaunchTemplate = {
            LaunchTemplateId = var.ec2.launch_template_id
            Version          = var.ec2.launch_template_version
          }
          "ClientToken.$" = "$.script_runner_host.client_token"
          SubnetId        = var.ec2.subnet_id
          MinCount        = 1
          MaxCount        = 1
          TagSpecifications = [{
            ResourceType = "instance"
            Tags = concat(
              [for key, value in merge(var.ec2.tags, { ManagedBy = var.ec2.managed_by }) : { Key = key, Value = value }],
              [{ Key = "BuildExecutionArn", "Value.$" = "$$.Execution.Id" }],
            )
          }]
        }
        ResultSelector = { "instance_id.$" = "$.Instances[0].InstanceId" }
        ResultPath     = "$.script_runner_host.instance"
        Retry          = local.disposable_api_retry
        Catch          = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.failure", Next = "${step.name}_failed" }]
        Next           = "${step.name}_wait_for_agent"
      }
      "${step.name}_wait_for_agent" = {
        Type    = "Wait"
        Seconds = 30
        Next    = "${step.name}_find_agent"
      }
      "${step.name}_find_agent" = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ecs:listContainerInstances"
        Parameters = {
          Cluster    = var.script_runner.cluster_arn
          Status     = "ACTIVE"
          "Filter.$" = "States.Format('ec2InstanceId == {} and agentConnected == true', $.script_runner_host.instance.instance_id)"
        }
        ResultSelector = { "container_arns.$" = "$.ContainerInstanceArns" }
        ResultPath     = "$.script_runner_host.registration"
        Retry          = local.disposable_api_retry
        Catch          = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.failure", Next = "${step.name}_terminate_instance" }]
        Next           = "${step.name}_check_agent"
      }
      "${step.name}_check_agent" = {
        Type = "Choice"
        Choices = [
          { Variable = "$.script_runner_host.registration.container_arns[0]", IsPresent = true, Next = step.name },
          { Variable = "$.script_runner_host.poll.attempts", NumericGreaterThanEquals = var.ec2.registration_attempts, Next = "${step.name}_registration_timed_out" },
        ]
        Default = "${step.name}_increment_registration_poll"
      }
      "${step.name}_increment_registration_poll" = {
        Type       = "Pass"
        Parameters = { "attempts.$" = "States.MathAdd($.script_runner_host.poll.attempts, 1)" }
        ResultPath = "$.script_runner_host.poll"
        Next       = "${step.name}_wait_for_agent"
      }
      "${step.name}_registration_timed_out" = {
        Type       = "Pass"
        Result     = { Error = "InstanceRegistrationTimeout", Cause = "The dedicated instance did not register a connected ECS agent within the polling limit." }
        ResultPath = "$.script_runner_host.failure"
        Next       = "${step.name}_terminate_instance"
      }
      "${step.name}_check_exit_code" = {
        Type = "Choice"
        Choices = [{
          And = [
            { Variable = "$.script_runner_host.task_result.Containers[0].ExitCode", IsPresent = true },
            { Variable = "$.script_runner_host.task_result.Containers[0].ExitCode", NumericEquals = 0 },
          ]
          Next = "${step.name}_terminate_instance"
        }]
        Default = "${step.name}_record_exit_failure"
      }
      "${step.name}_record_exit_failure" = {
        Type       = "Pass"
        Result     = { Error = "ScriptRunnerFailed", Cause = "The script runner did not report a successful container exit code; inspect its CloudWatch logs." }
        ResultPath = "$.script_runner_host.failure"
        Next       = "${step.name}_terminate_instance"
      }
    },
  )]...)

  disposable_expiry_definition = !local.ec2_mode || var.ec2 == null ? null : {
    StartAt        = "wait_for_expiry"
    TimeoutSeconds = var.ec2.max_lifetime_seconds + 1200
    States = merge(local.disposable_cleanup_states.__expiry, {
      wait_for_expiry = {
        Type    = "Wait"
        Seconds = var.ec2.max_lifetime_seconds
        Next    = "find_expired_instance"
      }
      find_expired_instance = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:describeInstances"
        Parameters = {
          Filters = [
            { Name = "client-token", "Values.$" = "States.Array($.client_token)" },
            { Name = "tag:ManagedBy", Values = [var.ec2.managed_by] },
            { Name = "instance-state-name", Values = ["pending", "running", "stopping", "stopped", "shutting-down"] },
          ]
        }
        ResultPath = "$.expired_instance"
        Retry      = local.disposable_api_retry
        Next       = "check_expired_instance"
      }
      check_expired_instance = {
        Type    = "Choice"
        Choices = [{ Variable = "$.expired_instance.Reservations[0].Instances[0].InstanceId", IsPresent = true, Next = "select_expired_instance" }]
        Default = "__expiry_finish"
      }
      select_expired_instance = {
        Type = "Pass"
        Parameters = {
          instance = { "instance_id.$" = "$.expired_instance.Reservations[0].Instances[0].InstanceId" }
        }
        ResultPath = "$.script_runner_host"
        Next       = "find_expired_agent"
      }
      find_expired_agent = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ecs:listContainerInstances"
        Parameters = {
          Cluster    = var.script_runner.cluster_arn
          "Filter.$" = "States.Format('ec2InstanceId == {}', $.script_runner_host.instance.instance_id)"
        }
        ResultSelector = { "container_arns.$" = "$.ContainerInstanceArns" }
        ResultPath     = "$.script_runner_host.registration"
        Retry          = local.disposable_api_retry
        Catch          = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.registration_failure", Next = "__expiry_terminate_instance" }]
        Next           = "__expiry_terminate_instance"
      }
    })
  }
}

resource "aws_cloudwatch_log_group" "disposable_expiry" {
  count             = local.ec2_mode && var.ec2 != null ? 1 : 0
  name              = "/aws/vendedlogs/states/${local.disposable_expiry_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_sfn_state_machine" "disposable_expiry" {
  count      = local.ec2_mode && var.ec2 != null ? 1 : 0
  name       = local.disposable_expiry_name
  role_arn   = var.execution_role_arn
  type       = "STANDARD"
  definition = jsonencode(local.disposable_expiry_definition)
  tags       = var.tags

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.disposable_expiry[0].arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }
}