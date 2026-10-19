locals {
  child_cleanup_states = merge({}, [for step in local.child_cleanup_steps : {
    "${step.name}_prepare_child" = {
      Type = "Pass"
      Parameters = {
        "input.$" = try(step.input_path, "$")
        context   = { "__script_runner_root_execution_arn.$" = "$$.Execution.Id" }
      }
      ResultPath = "$.__script_runner_child"
      Next       = step.name
    }
    # Allow in-flight EC2 launches to become visible before discovering orphaned hosts.
    "${step.name}_cleanup_settle" = {
      Type    = "Wait"
      Seconds = 30
      Next    = "${step.name}_find_orphaned_hosts"
    }
    "${step.name}_find_orphaned_hosts" = {
      Type     = "Task"
      Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:describeInstances"
      Parameters = {
        Filters = [
          { Name = "tag:ManagedBy", Values = [step.ec2_cleanup.managed_by] },
          { Name = "tag:RootExecutionArn", "Values.$" = "States.Array($$.Execution.Id)" },
          { Name = "instance-state-name", Values = ["pending", "running", "stopping", "stopped", "shutting-down"] },
        ]
      }
      ResultPath = "$.__script_runner_child.hosts"
      Retry      = local.disposable_api_retry
      Catch      = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.__script_runner_child.cleanup_failure", Next = "${step.name}_record_cleanup_failure" }]
      Next       = "${step.name}_check_orphaned_hosts"
    }
    "${step.name}_check_orphaned_hosts" = {
      Type = "Choice"
      Choices = [{
        Variable  = "$.__script_runner_child.hosts.Reservations[0]"
        IsPresent = true
        Next      = "${step.name}_clean_orphaned_hosts"
      }]
      Default = "${step.name}_child_failed"
    }
    "${step.name}_clean_orphaned_hosts" = {
      Type      = "Map"
      ItemsPath = "$.__script_runner_child.hosts.Reservations"
      ItemProcessor = {
        ProcessorConfig = { Mode = "INLINE" }
        StartAt         = "clean_instances"
        States = {
          clean_instances = {
            Type      = "Map"
            ItemsPath = "$.Instances"
            ItemProcessor = {
              ProcessorConfig = { Mode = "INLINE" }
              StartAt         = "terminate"
              States = {
                terminate = {
                  Type       = "Task"
                  Resource   = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:terminateInstances"
                  Parameters = { "InstanceIds.$" = "States.Array($.InstanceId)" }
                  ResultPath = null
                  Retry      = local.disposable_api_retry
                  Next       = "initialise_poll"
                }
                initialise_poll = {
                  Type       = "Pass"
                  Result     = { attempts = 0 }
                  ResultPath = "$.poll"
                  Next       = "wait"
                }
                wait = {
                  Type    = "Wait"
                  Seconds = 30
                  Next    = "describe"
                }
                describe = {
                  Type           = "Task"
                  Resource       = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:ec2:describeInstances"
                  Parameters     = { "InstanceIds.$" = "States.Array($.InstanceId)" }
                  ResultSelector = { "state.$" = "$.Reservations[0].Instances[0].State.Name" }
                  ResultPath     = "$.observed"
                  Retry          = local.disposable_api_retry
                  Next           = "check"
                }
                check = {
                  Type = "Choice"
                  Choices = [
                    { Variable = "$.observed.state", StringEquals = "terminated", Next = "done" },
                    { Variable = "$.poll.attempts", NumericGreaterThanEquals = 39, Next = "timed_out" },
                  ]
                  Default = "increment_poll"
                }
                increment_poll = {
                  Type       = "Pass"
                  Parameters = { "attempts.$" = "States.MathAdd($.poll.attempts, 1)" }
                  ResultPath = "$.poll"
                  Next       = "wait"
                }
                timed_out = {
                  Type  = "Fail"
                  Error = "InstanceTerminationTimeout"
                  Cause = "An orphaned build instance did not terminate within 40 termination checks."
                }
                done = { Type = "Succeed" }
              }
            }
            ResultPath = null
            End        = true
          }
        }
      }
      ResultPath = null
      Catch      = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.__script_runner_child.cleanup_failure", Next = "${step.name}_record_cleanup_failure" }]
      # Query again so pagination cannot leave hosts behind after processing a page.
      Next = "${step.name}_find_orphaned_hosts"
    }
    "${step.name}_child_failed" = {
      Type      = "Fail"
      ErrorPath = "$.__script_runner_child.failure.Error"
      CausePath = "$.__script_runner_child.failure.Cause"
    }
    "${step.name}_parent_cleanup_failed" = {
      Type      = "Fail"
      Error     = "ChildInstanceCleanupFailed"
      CausePath = "States.JsonToString($.__script_runner_child.cleanup_context)"
    }
    "${step.name}_record_cleanup_failure" = {
      Type = "Pass"
      Parameters = {
        "child_failure.$"   = "$.__script_runner_child.failure"
        "cleanup_failure.$" = "$.__script_runner_child.cleanup_failure"
      }
      ResultPath = "$.__script_runner_child.cleanup_context"
      Next       = "${step.name}_parent_cleanup_failed"
    }
  }]...)
}
