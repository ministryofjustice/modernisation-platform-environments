mock_provider "aws" {}

variables {
  name               = "test-script-runtime"
  execution_role_arn = "arn:aws:iam::123456789012:role/test-orchestration"
  steps = [
    {
      name        = "first"
      type        = "script_runner"
      script_path = "scripts/test.sh"
      shell_type  = "bash"
      result_path = "$.first"
    },
    {
      name        = "second"
      type        = "script_runner"
      script_path = "scripts/test.py"
      shell_type  = "python3"
      result_path = "$.second"
    },
  ]
  script_runner = {
    cluster_arn            = "arn:aws:ecs:eu-west-2:123456789012:cluster/test"
    task_definition_family = "test-script-runner"
    container_name         = "script-runner"
    subnets                = ["subnet-test"]
    security_groups        = ["sg-test"]
    assign_public_ip       = "DISABLED"
    execution_role_arn     = "arn:aws:iam::123456789012:role/test-execution"
    task_role_arn          = "arn:aws:iam::123456789012:role/test-task"
  }
}

run "fargate_defaults" {
  command = plan

  assert {
    condition = (
      local.definition.StartAt == "first_prepare_host" &&
      local.definition.States.first_prepare_host.Result.retry.attempts == 0 &&
      local.definition.States.first.Next == "first_check_exit_code" &&
      local.definition.States.first_check_exit_code.Choices[0].And[1].NumericEquals == 0 &&
      local.definition.States.first_check_exit_code.Choices[0].Next == "first_finish" &&
      local.definition.States.first_check_exit_code.Default == "first_check_script_retries" &&
      local.definition.States.first_check_script_retries.Choices[0].NumericLessThan == 3 &&
      local.definition.States.first_check_script_retries.Default == "first_record_exit_failure" &&
      local.definition.States.first_wait_for_script_retry.Next == "first"
    )
    error_message = "Fargate must check script exits and allow three additional runs before recording failure."
  }

  assert {
    condition = (
      local.definition.States.first_finish.ResultPath == "$.first" &&
      local.definition.States.first_finish.Next == "second_prepare_host" &&
      local.definition.States.second_prepare_host.Result.retry.attempts == 0 &&
      local.definition.States.second_finish.End &&
      local.definition.States.first_record_exit_failure.Next == "first_failed" &&
      local.definition.States.first_failed.Type == "Fail" &&
      local.definition.States.first_record_exit_failure.Parameters.Error == "ScriptRunnerFailed"
    )
    error_message = "Each step must reset its retry counter, preserve result paths, and fail explicitly on exhaustion."
  }
}

run "disabled_retries" {
  command = plan
  variables {
    step_function_retry_attempts = 0
  }
  assert {
    condition     = local.definition.States.first_check_script_retries.Choices[0].NumericLessThan == 0
    error_message = "Zero must disable reruns after the initial failure."
  }
}

run "ec2_custom_retries" {
  command = plan
  variables {
    step_function_retry_attempts = 5
    script_runner = {
      cluster_arn            = "arn:aws:ecs:eu-west-2:123456789012:cluster/test"
      task_definition_family = "test-script-runner"
      container_name         = "script-runner"
      subnets                = ["subnet-test"]
      security_groups        = ["sg-test"]
      assign_public_ip       = "DISABLED"
      execution_role_arn     = "arn:aws:iam::123456789012:role/test-execution"
      task_role_arn          = "arn:aws:iam::123456789012:role/test-task"
      launch_type            = "EC2"
    }
    ec2 = {
      launch_template_id      = "lt-test"
      launch_template_version = "1"
      subnet_id               = "subnet-test"
      managed_by              = "test"
      tags                    = {}
    }
  }
  assert {
    condition = (
      local.definition.States.first_prepare_host.Parameters.retry.attempts == 0 &&
      local.definition.States.first_check_script_retries.Choices[0].NumericLessThan == 5 &&
      local.definition.States.first_check_exit_code.Choices[0].Next == "first_terminate_instance" &&
      local.definition.States.first_record_exit_failure.Next == "first_terminate_instance" &&
      local.definition.States.first_wait_for_script_retry.Next == "first" &&
      local.definition.States.first_check_failure.Choices[0].Next == "first_failed" &&
      local.definition.States.first_finish.Next == "second_prepare_host"
    )
    error_message = "EC2 retries must reuse the host and clean it up on success or exhaustion before failing or continuing."
  }
}

run "invalid_retry_limit" {
  command = plan
  variables {
    step_function_retry_attempts = -1
  }
  expect_failures = [var.step_function_retry_attempts]
}

run "fractional_retry_limit" {
  command = plan
  variables {
    step_function_retry_attempts = 1.5
  }
  expect_failures = [var.step_function_retry_attempts]
}
