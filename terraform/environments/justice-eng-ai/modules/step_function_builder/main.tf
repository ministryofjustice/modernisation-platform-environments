data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  ec2_mode = try(var.script_runner.launch_type, "FARGATE") == "EC2"

  task_steps          = [for step in var.steps : step if step.type == "script_runner"]
  step_function_steps = [for step in var.steps : step if step.type == "step_function"]
  dynamodb_steps      = [for step in var.steps : step if step.type == "dynamodb_get_item"]
  query_steps         = [for step in var.steps : step if step.type == "dynamodb_query_latest"]
  build_query_steps   = [for step in var.steps : step if step.type == "dynamodb_query_build"]
  approval_steps      = [for step in var.steps : step if step.type == "wait_for_approval"]
  choice_steps        = [for step in var.steps : step if step.type == "choice"]
  child_cleanup_steps = [for step in local.step_function_steps : step if try(step.ec2_cleanup, null) != null]
  step_entrypoints = {
    for step in var.steps : step.name => step.type == "script_runner" ? "${step.name}_prepare_host" : step.type == "wait_for_approval" ? "${step.name}_next_key" : step.type == "dynamodb_query_build" ? "${step.name}_extract" : try(step.ec2_cleanup, null) != null ? "${step.name}_prepare_child" : step.name
  }

  transitions = {
    for index, step in var.steps : step.name => index < length(var.steps) - 1 ? {
      Next = local.step_entrypoints[var.steps[index + 1].name]
      } : {
      End = true
    }
  }

  task_states = {
    for step in local.task_steps : step.name => merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::ecs:runTask.${try(step.outputs, false) ? "waitForTaskToken" : "sync"}"
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
                # The container's exit hook sends the JSON in SCRIPT_OUTPUT_FILE back with this token.
                try(step.outputs, false) ? [
                  { Name = "SCRIPT_OUTPUT_FILE", Value = "/tmp/script-output.json" },
                  { Name = "TASK_TOKEN", "Value.$" = "$$.Task.Token" },
                ] : [],
              )
            }]
          }
          },
          { for key, value in {
            PlacementConstraints = [{
              Type           = "memberOf"
              "Expression.$" = "States.Format('ec2InstanceId == {}', $.script_runner_host.instance.instance_id)"
            }]
          } : key => value if local.ec2_mode },
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
      {
        # With outputs the task reports success or failure itself, so there is no exit code to check.
        Next       = try(step.outputs, false) ? (local.ec2_mode ? "${step.name}_terminate_instance" : "${step.name}_finish") : "${step.name}_check_exit_code"
        ResultPath = "$.script_runner_host.task_result"
        Catch      = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_host.failure", Next = local.ec2_mode ? "${step.name}_terminate_instance" : "${step.name}_failed" }]
      },
      local.ec2_mode ? { TimeoutSeconds = try(step.timeout_seconds, 3600) } : try(step.timeout_seconds, null) == null ? {} : { TimeoutSeconds = step.timeout_seconds },
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
          "Input.$"       = try(step.ec2_cleanup, null) == null ? try(step.input_path, "$") : "States.JsonMerge($.script_runner_child.input, $.script_runner_child.context, false)"
        }
      },
      local.transitions[step.name],
      try(step.timeout_seconds, null) == null ? {} : { TimeoutSeconds = step.timeout_seconds },
      try(step.result_path, null) == null ? {} : { ResultPath = step.result_path },
      length(try(step.retry, [])) == 0 ? {} : { Retry = step.retry },
      try(step.ec2_cleanup, null) == null ? {} : {
        Catch = [{ ErrorEquals = ["States.ALL"], ResultPath = "$.script_runner_child.failure", Next = "${step.name}_cleanup_settle" }]
      }
    )
  }

  # Native DynamoDB read (no Lambda). key maps attribute name => JSONPath/intrinsic
  # giving the string key value. Without result_attributes the raw result
  # ({Item = {...}}, with no Item when nothing exists) is returned.
  dynamodb_states = {
    for step in local.dynamodb_steps : step.name => merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::dynamodb:getItem"
        Parameters = {
          TableName      = step.table_name
          ConsistentRead = true
          Key            = { for name, expression in step.key : name => { "S.$" = expression } }
        }
      },
      length(try(step.result_attributes, [])) == 0 ? {} : {
        ResultSelector = { for name in step.result_attributes : "${name}.$" => "$.Item.${name}.S" }
      },
      local.transitions[step.name],
      try(step.result_path, null) == null ? {} : { ResultPath = step.result_path },
      length(try(step.retry, [])) == 0 ? {} : { Retry = step.retry }
    )
  }

  # Reads the newest event for a hash key (no Lambda): the highest range key above 0,
  # so a counter item stored at range key 0 is skipped. hash_key is a JSONPath or
  # intrinsic for the string hash key value; result_attributes maps attribute name =>
  # DynamoDB type ("S" or "N") and returns those attributes, as strings, at the top
  # level of the result. N values come back as strings.
  query_states = {
    for step in local.query_steps : step.name => merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:dynamodb:query"
        Parameters = {
          TableName                = step.table_name
          KeyConditionExpression   = "#hash = :hash AND #range > :floor"
          ExpressionAttributeNames = { "#hash" = try(step.hash_key_name, "AppID"), "#range" = try(step.range_key_name, "SysKey") }
          ExpressionAttributeValues = {
            ":hash"  = { "S.$" = step.hash_key }
            ":floor" = { N = "0" }
          }
          ScanIndexForward = false
          ConsistentRead   = true
          Limit            = 1
        }
        ResultSelector = { for name, type in step.result_attributes : "${name}.$" => "$.Items[0].${name}.${type}" }
      },
      local.transitions[step.name],
      try(step.result_path, null) == null ? {} : { ResultPath = step.result_path },
      length(try(step.retry, [])) == 0 ? {} : { Retry = step.retry }
    ) if try(step.build_id, null) == null
  }

  # FilterExpression is evaluated after each page. A page can be empty even
  # when the requested build exists. Keep the cursor until a match or exhaustion.
  # Limit and projection bound each response independently of build history size.
  paginated_query_specs = merge(
    { for step in local.query_steps : step.name => {
      parameters = {
        TableName                = step.table_name
        KeyConditionExpression   = "#hash = :hash AND #range > :floor"
        ExpressionAttributeNames = { "#hash" = try(step.hash_key_name, "AppID"), "#range" = try(step.range_key_name, "SysKey") }
        FilterExpression         = "BuildID = :build_id"
        ExpressionAttributeValues = {
          ":hash"     = { "S.$" = step.hash_key }
          ":floor"    = { N = "0" }
          ":build_id" = { "N.$" = step.build_id }
        }
        ProjectionExpression = join(", ", keys(step.result_attributes))
        ScanIndexForward     = false
        ConsistentRead       = true
        Limit                = 1
      }
      cursor_key  = try(step.hash_key_name, "AppID")
      selectors   = { for name, type in step.result_attributes : "${name}.$" => "$.__build_query.Items[0].${name}.${type}" }
      result_path = try(step.result_path, null)
      transition  = local.transitions[step.name]
      retry       = try(step.retry, [])
    } if try(step.build_id, null) != null },
    { for step in local.build_query_steps : step.name => {
      parameters = {
        TableName              = step.table_name
        KeyConditionExpression = "AppID = :app_id AND SysKey > :floor"
        FilterExpression       = "BuildID = :build_id"
        ExpressionAttributeValues = {
          ":app_id"   = { "S.$" = "$.package_identity.AppID" }
          ":floor"    = { N = "0" }
          ":build_id" = { "N.$" = "States.Format('{}', $.package_identity.BuildID)" }
        }
        ProjectionExpression = join(", ", keys(step.result_attributes))
        ScanIndexForward     = false
        ConsistentRead       = true
        Limit                = 1
      }
      cursor_key  = "AppID"
      selectors   = { for name, type in step.result_attributes : "${name}.$" => "$.__build_query.Items[0].${name}.${type}" }
      result_path = try(step.result_path, null)
      transition  = local.transitions[step.name]
      retry       = try(step.retry, [])
    } },
    { for step in local.approval_steps : "find_waiting_event" => {
      parameters = {
        TableName              = step.table_name
        KeyConditionExpression = "AppID = :app AND SysKey > :floor"
        FilterExpression       = "BuildID = :build AND JobStatus = :status"
        ExpressionAttributeValues = {
          ":app"    = { "S.$" = "$.AppID" }
          ":build"  = { "N.$" = "$.BuildID" }
          ":floor"  = { N = "0" }
          ":status" = { S = try(step.job_status, "awaiting_approval") }
        }
        ProjectionExpression = "TaskToken"
        ScanIndexForward     = false
        ConsistentRead       = true
        Limit                = 1
      }
      cursor_key  = "AppID"
      selectors   = { "token.$" = "$.__build_query.Items[0].TaskToken.S" }
      result_path = "$.waiting_event"
      transition  = { Next = "route_decision" }
      retry       = []
    } }
  )

  paginated_query_state_groups = { for name, query in local.paginated_query_specs : name => {
    (name) = merge({
      Type       = "Task"
      Resource   = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:dynamodb:query"
      Parameters = query.parameters
      ResultPath = "$.__build_query"
      Next       = "${name}_check_page"
    }, length(query.retry) == 0 ? {} : { Retry = query.retry })
    "${name}_next_page" = merge({
      Type       = "Task"
      Resource   = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:dynamodb:query"
      Parameters = merge(query.parameters, { "ExclusiveStartKey.$" = "$.__build_query.LastEvaluatedKey" })
      ResultPath = "$.__build_query"
      Next       = "${name}_check_page"
    }, length(query.retry) == 0 ? {} : { Retry = query.retry })
    "${name}_check_page" = {
      Type = "Choice"
      Choices = [
        { Variable = "$.__build_query.Items[0]", IsPresent = true, Next = "${name}_select" },
        { Variable = "$.__build_query.LastEvaluatedKey.${query.cursor_key}", IsPresent = true, Next = "${name}_next_page" },
      ]
      Default = "${name}_not_found"
    }
    "${name}_select" = merge({
      Type       = "Pass"
      Parameters = query.selectors
    }, query.result_path == null ? {} : { ResultPath = query.result_path }, query.transition)
    "${name}_not_found" = {
      Type  = "Fail"
      Error = "BuildEventNotFound"
      Cause = "No matching build event exists after querying all pages."
    }
  } }
  paginated_query_states = merge({}, [for name, states in local.paginated_query_state_groups : states if name != "find_waiting_event"]...)

  # Resolves a Forge package stem to its review event. Versioned stems use
  # ``<AppID>~<BuildID>`` and query that exact numeric build; legacy stems use
  # the newest event for the AppID so application-first rollouts remain safe.
  build_query_states = merge({}, [for step in local.build_query_steps : {
    "${step.name}_extract" = {
      Type       = "Pass"
      Parameters = { "stem.$" = step.package_stem }
      ResultPath = "$.package_identity"
      Next       = "${step.name}_detect"
    }
    "${step.name}_detect" = {
      Type = "Choice"
      Choices = [{
        Variable      = "$.package_identity.stem"
        StringMatches = "*~*"
        Next          = "${step.name}_prepare_exact"
      }]
      Default = "${step.name}_prepare_latest"
    }
    "${step.name}_prepare_exact" = {
      Type = "Pass"
      Parameters = {
        "AppID.$"   = "States.ArrayGetItem(States.StringSplit($.package_identity.stem, '~'), 0)"
        "BuildID.$" = "States.StringToJson(States.ArrayGetItem(States.StringSplit($.package_identity.stem, '~'), 1))"
      }
      ResultPath = "$.package_identity"
      Next       = step.name
    }
    "${step.name}_prepare_latest" = {
      Type = "Pass"
      Parameters = {
        "AppID.$" = "$.package_identity.stem"
      }
      ResultPath = "$.package_identity"
      Next       = "${step.name}_latest"
    }
    "${step.name}_latest" = merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:dynamodb:query"
        Parameters = {
          TableName              = step.table_name
          KeyConditionExpression = "AppID = :app_id AND SysKey > :floor"
          ExpressionAttributeValues = {
            ":app_id" = { "S.$" = "$.package_identity.AppID" }
            ":floor"  = { N = "0" }
          }
          ScanIndexForward     = false
          Limit                = 1
          ConsistentRead       = true
          ProjectionExpression = join(", ", keys(step.result_attributes))
        }
        ResultSelector = { for name, type in step.result_attributes : "${name}.$" => "$.Items[0].${name}.${type}" }
      },
      local.transitions[step.name],
      try(step.result_path, null) == null ? {} : { ResultPath = step.result_path },
      length(try(step.retry, [])) == 0 ? {} : { Retry = step.retry }
    )
  }]...)

  # Pauses the execution until an external caller sends the task token back
  # (SendTaskSuccess/SendTaskFailure). Appends an event to the build events table that
  # holds the token, with a SysKey taken from the table's counter item
  # (hash key + range key 0, attribute LastSysKey), in two native steps:
  #   <name>_next_key  increments the counter
  #   <name>           writes the event and waits for the callback
  approval_states = merge({}, [for step in local.approval_steps : {
    "${step.name}_next_key" = {
      Type     = "Task"
      Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:dynamodb:updateItem"
      Parameters = {
        TableName                 = step.table_name
        Key                       = { AppID = { "S.$" = step.app_id }, SysKey = { N = "0" } }
        UpdateExpression          = "ADD LastSysKey :one"
        ExpressionAttributeValues = { ":one" = { N = "1" } }
        ReturnValues              = "UPDATED_NEW"
      }
      ResultSelector = { "value.$" = "$.Attributes.LastSysKey.N" }
      ResultPath     = "$.${step.name}_event"
      Next           = step.name
    }
    (step.name) = merge(
      {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:dynamodb:putItem.waitForTaskToken"
        Parameters = {
          TableName = step.table_name
          Item = merge(
            {
              SysKey    = { "N.$" = "$.${step.name}_event.value" }
              AppID     = { "S.$" = step.app_id }
              BuildID   = { "N.$" = step.build_id }
              JobStage  = { S = step.job_stage }
              JobStatus = { S = try(step.job_status, "awaiting_approval") }
              Date      = { "S.$" = "$$.State.EnteredTime" }
              TaskToken = { "S.$" = "$$.Task.Token" }
            },
            try(step.user_name, null) == null ? {} : { UserName = { "S.$" = step.user_name } }
          )
        }
        ResultPath     = coalesce(try(step.result_path, null), "$.${step.name}_result")
        TimeoutSeconds = try(step.timeout_seconds, 31536000)
      },
      local.transitions[step.name]
    )
  }]...)

  # Continues to the next step when the string at variable equals the given
  # value (or, with when_absent, when variable is absent); otherwise the execution ends successfully at <name>_stop.
  choice_states = merge({}, [for step in local.choice_steps : {
    (step.name) = {
      Type = "Choice"
      Choices = [merge(
        { Next = local.transitions[step.name].Next },
        try(step.when_absent, false) ? { Not = { Variable = step.variable, IsPresent = true } } : {},
        try(step.when_absent, false) ? {} : { Variable = step.variable, StringEquals = step.equals },
      )]
      Default = "${step.name}_stop"
    }
    "${step.name}_stop" = {
      Type    = "Succeed"
      Comment = try(step.stop_comment, "Condition not met; execution ends successfully.")
    }
  }]...)

  definition = {
    Comment = "Runs an ordered process using ECS script runner tasks and nested Step Functions."
    StartAt = local.step_entrypoints[var.steps[0].name]
    States  = merge(local.task_states, local.step_function_states, local.dynamodb_states, local.query_states, local.paginated_query_states, local.build_query_states, local.approval_states, local.choice_states, local.disposable_lifecycle_states, local.script_runtime_states, local.fargate_lifecycle_states, local.child_cleanup_states)
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

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    precondition {
      condition     = local.ec2_mode ? var.ec2 != null : var.ec2 == null
      error_message = "EC2 mode requires ec2 host settings. FARGATE mode must not supply ec2 host settings."
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

# Companion state machine for a wait_for_approval step. Start it with the DynamoDB stream
# record of an approval or rejection event (an array holding one record); it finds the task
# token stored by the matching awaiting_approval event and completes the paused task.
resource "aws_sfn_state_machine" "resume" {
  count = length(local.approval_steps) > 0 ? 1 : 0

  name     = "${var.name}-resume"
  role_arn = var.execution_role_arn
  type     = "STANDARD"
  tags     = var.tags

  definition = jsonencode({
    Comment = "Resumes the ${var.name} execution waiting for this approval."
    StartAt = "extract_decision"
    States = merge(try(local.paginated_query_state_groups["find_waiting_event"], {}), {
      extract_decision = {
        Type = "Pass"
        Parameters = {
          "AppID.$"     = "$[0].dynamodb.NewImage.AppID.S"
          "BuildID.$"   = "$[0].dynamodb.NewImage.BuildID.N"
          "JobStatus.$" = "$[0].dynamodb.NewImage.JobStatus.S"
        }
        Next = "find_waiting_event"
      }
      route_decision = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.JobStatus"
            StringEquals = "approved"
            Next         = "send_task_success"
          },
          {
            Variable     = "$.JobStatus"
            StringEquals = "rejected"
            Next         = "send_task_failure"
          },
        ]
        Default = "unexpected_status"
      }
      send_task_success = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:sfn:sendTaskSuccess"
        Parameters = {
          "TaskToken.$" = "$.waiting_event.token"
          Output        = "{}"
        }
        Retry = [{ ErrorEquals = ["States.TaskFailed"], IntervalSeconds = 2, BackoffRate = 2, MaxAttempts = 3 }]
        Catch = [
          { ErrorEquals = ["Sfn.InvalidTokenException", "Sfn.TaskDoesNotExistException", "Sfn.TaskTimedOutException"], Next = "already_resumed" },
          { ErrorEquals = ["States.ALL"], Next = "callback_failed" },
        ]
        End = true
      }
      send_task_failure = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:sfn:sendTaskFailure"
        Parameters = {
          "TaskToken.$" = "$.waiting_event.token"
          Error         = "ReviewRejected"
          Cause         = "Application review was rejected"
        }
        Retry = [{ ErrorEquals = ["States.TaskFailed"], IntervalSeconds = 2, BackoffRate = 2, MaxAttempts = 3 }]
        Catch = [
          { ErrorEquals = ["Sfn.InvalidTokenException", "Sfn.TaskDoesNotExistException", "Sfn.TaskTimedOutException"], Next = "already_resumed" },
          { ErrorEquals = ["States.ALL"], Next = "callback_failed" },
        ]
        End = true
      }
      unexpected_status = {
        Type  = "Fail"
        Error = "UnexpectedReviewStatus"
        Cause = "Review callback status must be approved or rejected"
      }
      already_resumed = {
        Type    = "Succeed"
        Comment = "Nothing is waiting for this review decision."
      }
      callback_failed = {
        Type  = "Fail"
        Error = "ReviewCallbackFailed"
        Cause = "The paused execution could not be resumed."
      }
    })
  })
}