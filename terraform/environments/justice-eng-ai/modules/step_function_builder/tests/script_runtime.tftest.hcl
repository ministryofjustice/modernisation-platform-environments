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

  assert {
    condition = (
      local.definition.States.first_prepare_host.Next == "first_check_root_context" &&
      local.definition.States.first_prepare_host.Parameters["owner_execution_arn.$"] == "$$.Execution.Id" &&
      local.definition.States.first_check_root_context.Default == "first_launch_instance" &&
      local.definition.States.first_set_root_context.ResultPath == "$.script_runner_host.owner_execution_arn" &&
      local.definition.States.first_launch_instance.Parameters.TagSpecifications[0].Tags[2].Key == "RootExecutionArn" &&
      local.definition.States.first_launch_instance.Parameters.TagSpecifications[0].Tags[2]["Value.$"] == "$.script_runner_host.owner_execution_arn"
    )
    error_message = "EC2 hosts must use the supplied root execution context, falling back to their own execution for standalone runs."
  }

  assert {
    condition = (
      local.definition.States.first_terminate_instance.ResultSelector.attempts == 0 &&
      local.definition.States.first_describe_instance.Next == "first_check_termination" &&
      local.definition.States.first_describe_instance.ResultSelector["state.$"] == "$.Reservations[0].Instances[0].State.Name" &&
      local.definition.States.first_check_termination.Choices[0].StringEquals == "terminated" &&
      local.definition.States.first_check_termination.Choices[0].Next == "first_check_registration" &&
      local.definition.States.first_check_termination.Choices[1].NumericGreaterThanEquals == 39 &&
      local.definition.States.first_check_termination.Default == "first_increment_termination_poll" &&
      local.definition.States.first_increment_termination_poll.Next == "first_wait_for_termination" &&
      local.definition.States.first_termination_timed_out.Error == "InstanceTerminationTimeout" &&
      local.definition.States.first_report_termination.Parameters["state.$"] == "$.script_runner_host.termination_state.observed.state"
    )
    error_message = "Normal cleanup must confirm termination, poll at most 40 times, and fail explicitly if the instance remains alive."
  }
}

run "root_child_cleanup" {
  command = plan
  variables {
    script_runner = null
    steps = [
      {
        name               = "control"
        type               = "step_function"
        state_machine_name = "test-control"
        result_path        = "$.control"
      },
      {
        name               = "build"
        type               = "step_function"
        state_machine_name = "test-build"
        input_path         = "$.control.Output"
        result_path        = "$.build"
        ec2_cleanup        = { managed_by = "test-disposable-build" }
        retry              = [{ ErrorEquals = ["States.TaskFailed"], MaxAttempts = 2 }]
      },
      {
        name               = "deploy"
        type               = "step_function"
        state_machine_name = "test-deploy"
      },
    ]
  }

  assert {
    condition = (
      local.definition.StartAt == "control" &&
      local.definition.States.control.Next == "build_prepare_child" &&
      !can(local.definition.States.control.Catch) &&
      !can(local.definition.States.deploy.Catch) &&
      local.definition.States.build_prepare_child.Parameters["input.$"] == "$.control.Output" &&
      local.definition.States.build_prepare_child.Parameters.context["__script_runner_root_execution_arn.$"] == "$$.Execution.Id" &&
      local.definition.States.build_prepare_child.Next == "build" &&
      local.definition.States.build.Parameters["Input.$"] == "States.JsonMerge($.script_runner_child.input, $.script_runner_child.context, false)" &&
      local.definition.States.build.ResultPath == "$.build" &&
      local.definition.States.build.Next == "deploy" &&
      local.definition.States.build.Retry[0].MaxAttempts == 2 &&
      local.definition.States.build.Catch[0].Next == "build_cleanup_settle"
    )
    error_message = "Opt-in child cleanup must preserve input selection, result paths, ordering, and task retries without changing other children."
  }

  assert {
    condition = (
      local.definition.States.build_find_orphaned_hosts.Parameters.Filters[0].Name == "tag:ManagedBy" &&
      local.definition.States.build_find_orphaned_hosts.Parameters.Filters[0].Values[0] == "test-disposable-build" &&
      local.definition.States.build_find_orphaned_hosts.Parameters.Filters[1].Name == "tag:RootExecutionArn" &&
      local.definition.States.build_find_orphaned_hosts.Parameters.Filters[1]["Values.$"] == "States.Array($$.Execution.Id)" &&
      local.definition.States.build_check_orphaned_hosts.Default == "build_child_failed" &&
      local.definition.States.build_clean_orphaned_hosts.Next == "build_find_orphaned_hosts" &&
      local.definition.States.build_child_failed.ErrorPath == "$.script_runner_child.failure.Error" &&
      local.definition.States.build_child_failed.CausePath == "$.script_runner_child.failure.Cause" &&
      local.definition.States.build_clean_orphaned_hosts.Catch[0].Next == "build_record_cleanup_failure" &&
      local.definition.States.build_record_cleanup_failure.Parameters["child_failure.$"] == "$.script_runner_child.failure" &&
      local.definition.States.build_record_cleanup_failure.Parameters["cleanup_failure.$"] == "$.script_runner_child.cleanup_failure" &&
      local.definition.States.build_parent_cleanup_failed.CausePath == "States.JsonToString($.script_runner_child.cleanup_context)"
    )
    error_message = "Fallback cleanup must isolate this root's managed hosts, handle empty results/pages, and preserve both child and cleanup errors."
  }

  assert {
    condition = (
      local.definition.States.build_clean_orphaned_hosts.ItemProcessor.States.clean_instances.ItemProcessor.States.terminate.Parameters["InstanceIds.$"] == "States.Array($.InstanceId)" &&
      local.definition.States.build_clean_orphaned_hosts.ItemProcessor.States.clean_instances.ItemProcessor.States.check.Choices[0].StringEquals == "terminated" &&
      local.definition.States.build_clean_orphaned_hosts.ItemProcessor.States.clean_instances.ItemProcessor.States.check.Choices[1].NumericGreaterThanEquals == 39 &&
      local.definition.States.build_clean_orphaned_hosts.ItemProcessor.States.clean_instances.ItemProcessor.States.check.Default == "increment_poll" &&
      local.definition.States.build_clean_orphaned_hosts.ItemProcessor.States.clean_instances.ItemProcessor.States.increment_poll.Next == "wait" &&
      local.definition.States.build_clean_orphaned_hosts.ItemProcessor.States.clean_instances.ItemProcessor.States.timed_out.Error == "InstanceTerminationTimeout"
    )
    error_message = "Every orphaned instance must be terminated and polled with a bounded wait, rather than merely deregistered from ECS."
  }
}

run "cleanup_first_step" {
  command = plan
  variables {
    script_runner = null
    steps = [{
      name               = "build"
      type               = "step_function"
      state_machine_name = "test-build"
      ec2_cleanup        = { managed_by = "test-disposable-build" }
    }]
  }
  assert {
    condition = (
      local.definition.StartAt == "build_prepare_child" &&
      local.definition.States.build_prepare_child.Parameters["input.$"] == "$" &&
      local.definition.States.build.End &&
      !can(local.definition.States.build.Retry)
    )
    error_message = "A cleanup-enabled first/only child must initialise context and retain the default input and retry behaviour."
  }
}

run "invalid_cleanup_tag" {
  command = plan
  variables {
    script_runner = null
    steps = [{
      name               = "build"
      type               = "step_function"
      state_machine_name = "test-build"
      ec2_cleanup        = { managed_by = "" }
    }]
  }
  expect_failures = [var.steps]
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

run "review_gate_steps" {
  command = plan
  variables {
    steps = [
      {
        name        = "first"
        type        = "script_runner"
        script_path = "scripts/test.sh"
        shell_type  = "bash"
        result_path = "$.first"
      },
      {
        name              = "read_decision"
        type              = "dynamodb_get_item"
        table_name        = "review-queue"
        key               = { AppID = "$.app_id" }
        result_attributes = ["AppID", "status"]
        result_path       = "$"
      },
      {
        name     = "gate"
        type     = "choice"
        variable = "$.status"
        equals   = "approved"
      },
      {
        name               = "child"
        type               = "step_function"
        state_machine_name = "child-machine"
      },
    ]
  }

  assert {
    condition = (
      local.definition.States.first_finish.Next == "read_decision" &&
      endswith(local.definition.States.read_decision.Resource, ":states:::dynamodb:getItem") &&
      local.definition.States.read_decision.Parameters.Key.AppID["S.$"] == "$.app_id" &&
      local.definition.States.read_decision.ResultSelector["status.$"] == "$.Item.status.S" &&
      local.definition.States.read_decision.ResultPath == "$" &&
      local.definition.States.read_decision.Next == "gate"
    )
    error_message = "dynamodb_get_item must read the item natively and flatten the requested attributes."
  }

  assert {
    condition = (
      local.definition.States.gate.Choices[0].StringEquals == "approved" &&
      local.definition.States.gate.Choices[0].Next == "child" &&
      local.definition.States.gate.Default == "gate_stop" &&
      local.definition.States.gate_stop.Type == "Succeed"
    )
    error_message = "choice must continue when matched and otherwise succeed without running later steps."
  }
}

run "choice_cannot_be_last" {
  command = plan
  variables {
    steps = [
      {
        name     = "gate"
        type     = "choice"
        variable = "$.status"
        equals   = "approved"
      },
    ]
  }
  expect_failures = [var.steps]
}

run "review_gate_when_absent" {
  command = plan
  variables {
    steps = [
      {
        name        = "read_record"
        type        = "dynamodb_get_item"
        table_name  = "review-queue"
        key         = { AppID = "$.app_id" }
        result_path = "$.review"
      },
      {
        name        = "gate"
        type        = "choice"
        variable    = "$.review.Item"
        when_absent = true
      },
      {
        name               = "child"
        type               = "step_function"
        state_machine_name = "child-machine"
      },
    ]
  }

  assert {
    condition = (
      !contains(keys(local.definition.States.read_record), "ResultSelector") &&
      local.definition.States.read_record.ResultPath == "$.review" &&
      local.definition.States.gate.Choices[0].Not.Variable == "$.review.Item" &&
      local.definition.States.gate.Choices[0].Not.IsPresent == true &&
      local.definition.States.gate.Choices[0].Next == "child" &&
      local.definition.States.gate.Default == "gate_stop"
    )
    error_message = "when_absent must continue only when the variable is missing, and the raw item must be returned without a ResultSelector."
  }
}

run "latest_event_and_approval_wait" {
  command = plan
  variables {
    steps = [
      {
        name              = "latest"
        type              = "dynamodb_query_latest"
        table_name        = "build-details"
        hash_key          = "$.AppID"
        result_attributes = { BuildID = "N", JobStatus = "S" }
        result_path       = "$.latest"
      },
      {
        name     = "gate"
        type     = "choice"
        variable = "$.latest.JobStatus"
        equals   = "awaiting_approval"
      },
      {
        name       = "wait_for_approval"
        type       = "wait_for_approval"
        table_name = "build-details"
        app_id     = "$.AppID"
        build_id   = "$.BuildID"
        user_name  = "$.UserName"
        job_stage  = "control_plane"
      },
    ]
  }

  assert {
    condition = (
      endswith(local.definition.States.latest.Resource, ":states:::aws-sdk:dynamodb:query") &&
      local.definition.States.latest.Parameters.ScanIndexForward == false &&
      local.definition.States.latest.Parameters.Limit == 1 &&
      local.definition.States.latest.Parameters.ExpressionAttributeValues[":hash"]["S.$"] == "$.AppID" &&
      local.definition.States.latest.ResultSelector["BuildID.$"] == "$.Items[0].BuildID.N" &&
      local.definition.States.latest.ResultSelector["JobStatus.$"] == "$.Items[0].JobStatus.S" &&
      local.definition.States.latest.ResultPath == "$.latest" &&
      local.definition.States.latest.Next == "gate"
    )
    error_message = "dynamodb_query_latest must read the newest event and flatten the requested attributes."
  }

  assert {
    condition = (
      local.definition.States.gate.Choices[0].Next == "wait_for_approval_next_key" &&
      local.definition.States.wait_for_approval_next_key.Parameters.UpdateExpression == "ADD LastSysKey :one" &&
      local.definition.States.wait_for_approval_next_key.ResultPath == "$.wait_for_approval_event" &&
      local.definition.States.wait_for_approval_next_key.Next == "wait_for_approval"
    )
    error_message = "wait_for_approval must first increment the counter."
  }

  assert {
    condition = (
      endswith(local.definition.States.wait_for_approval.Resource, ":states:::aws-sdk:dynamodb:putItem.waitForTaskToken") &&
      local.definition.States.wait_for_approval.Parameters.Item.TaskToken["S.$"] == "$$.Task.Token" &&
      local.definition.States.wait_for_approval.Parameters.Item.SysKey["N.$"] == "$.wait_for_approval_event.value" &&
      local.definition.States.wait_for_approval.Parameters.Item.JobStatus.S == "awaiting_approval" &&
      local.definition.States.wait_for_approval.Parameters.Item.UserName["S.$"] == "$.UserName" &&
      local.definition.States.wait_for_approval.ResultPath == "$.wait_for_approval_result" &&
      local.definition.States.wait_for_approval.TimeoutSeconds == 31536000 &&
      local.definition.States.wait_for_approval.End == true
    )
    error_message = "wait_for_approval must store the task token in an event and wait for the callback."
  }
}

run "wait_for_approval_requires_fields" {
  command = plan
  variables {
    steps = [
      {
        name       = "wait_for_approval"
        type       = "wait_for_approval"
        table_name = "build-details"
      },
    ]
  }
  expect_failures = [var.steps]
}

run "resume_state_machine_created_with_approval_step" {
  command = plan
  variables {
    name = "control"
    steps = [
      {
        name       = "wait_for_approval"
        type       = "wait_for_approval"
        table_name = "build-details"
        app_id     = "$.AppID"
        build_id   = "$.BuildID"
        job_stage  = "control_plane"
      },
    ]
  }

  assert {
    condition = (
      length(aws_sfn_state_machine.resume) == 1 &&
      aws_sfn_state_machine.resume[0].name == "control-resume" &&
      strcontains(aws_sfn_state_machine.resume[0].definition, "sendTaskSuccess") &&
      strcontains(aws_sfn_state_machine.resume[0].definition, "build-details")
    )
    error_message = "A wait_for_approval step must create the companion resume state machine for its table."
  }
}

run "no_resume_state_machine_without_approval_step" {
  command = plan
  variables {
    steps = [
      {
        name       = "read"
        type       = "dynamodb_get_item"
        table_name = "t"
        key        = { AppID = "States.Format('x')" }
      },
    ]
  }

  assert {
    condition     = length(aws_sfn_state_machine.resume) == 0
    error_message = "Without a wait_for_approval step no resume state machine is created."
  }
}

run "only_one_approval_step" {
  command = plan
  variables {
    steps = [
      { name = "a", type = "wait_for_approval", table_name = "t", app_id = "$.AppID", build_id = "$.BuildID", job_stage = "x" },
      { name = "b", type = "wait_for_approval", table_name = "t", app_id = "$.AppID", build_id = "$.BuildID", job_stage = "y" },
    ]
  }
  expect_failures = [var.steps]
}
