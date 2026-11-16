locals {
  script_runtime_states = merge({}, [for step in local.task_steps : {
    "${step.name}_check_exit_code" = {
      Type = "Choice"
      Choices = [{
        And = [
          { Variable = "$.script_runner_host.task_result.Containers[0].ExitCode", IsPresent = true },
          { Variable = "$.script_runner_host.task_result.Containers[0].ExitCode", NumericEquals = 0 },
        ]
        Next = local.ec2_mode ? "${step.name}_terminate_instance" : "${step.name}_finish"
      }]
      Default = "${step.name}_check_script_retries"
    }
    "${step.name}_check_script_retries" = {
      Type = "Choice"
      Choices = [{
        Variable        = "$.script_runner_host.retry.attempts"
        NumericLessThan = var.step_function_retry_attempts
        Next            = "${step.name}_increment_script_retry"
      }]
      Default = "${step.name}_record_exit_failure"
    }
    "${step.name}_increment_script_retry" = {
      Type       = "Pass"
      Parameters = { "attempts.$" = "States.MathAdd($.script_runner_host.retry.attempts, 1)" }
      ResultPath = "$.script_runner_host.retry"
      Next       = "${step.name}_wait_for_script_retry"
    }
    "${step.name}_wait_for_script_retry" = {
      Type    = "Wait"
      Seconds = 15
      Next    = step.name
    }
    "${step.name}_record_exit_failure" = {
      Type = "Pass"
      Parameters = {
        Error     = "ScriptRunnerFailed"
        "Cause.$" = "States.JsonToString($.script_runner_host.task_result)"
      }
      ResultPath = "$.script_runner_host.failure"
      Next       = local.ec2_mode ? "${step.name}_terminate_instance" : "${step.name}_failed"
    }
  } if !try(step.outputs, false)]...)

  fargate_lifecycle_states = merge({}, [for step in local.task_steps : {
    "${step.name}_prepare_host" = {
      Type       = "Pass"
      Result     = { retry = { attempts = 0 } }
      ResultPath = "$.script_runner_host"
      Next       = step.name
    }
    "${step.name}_failed" = {
      Type      = "Fail"
      ErrorPath = "$.script_runner_host.failure.Error"
      CausePath = "$.script_runner_host.failure.Cause"
    }
    "${step.name}_finish" = merge(
      {
        Type       = "Pass"
        InputPath  = "$.script_runner_host.task_result"
        ResultPath = coalesce(try(step.result_path, null), "$")
      },
      local.transitions[step.name],
    )
  } if !local.ec2_mode]...)
}
