locals {
  step_functions_child_state_machine_arns = [
    "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.application_name}-*"
  ]
  step_functions_child_execution_arns = [
    "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:execution:${local.application_name}-*:*"
  ]
}

data "aws_iam_policy_document" "step_functions_common_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "step_functions_common" {
  name               = "${local.application_name}-step-functions"
  assume_role_policy = data.aws_iam_policy_document.step_functions_common_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "step_functions_common" {
  statement {
    sid       = "RunScriptRunnerTasks"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.script_runner_task_definition_family}:*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.script_runner.arn]
    }
  }

  statement {
    #checkov:skip=CKV_AWS_111 -- ECS task ARNs are created at runtime and cannot be scoped in advance.
    sid       = "ManageScriptRunnerTasks"
    effect    = "Allow"
    actions   = ["ecs:StopTask", "ecs:DescribeTasks"]
    resources = ["*"]
  }

  statement {
    sid     = "PassScriptRunnerRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.script_runner_ecs_execution.arn,
      aws_iam_role.script_runner_ecs_task.arn,
    ]
  }

  statement {
    sid    = "AllowEcsRunTaskSyncEventRule"
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"]
  }

  statement {
    sid       = "StartChildStateMachines"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = local.step_functions_child_state_machine_arns
  }

  statement {
    sid       = "ManageChildStateMachineExecutions"
    effect    = "Allow"
    actions   = ["states:DescribeExecution", "states:StopExecution"]
    resources = local.step_functions_child_execution_arns
  }

  statement {
    sid    = "AllowNestedExecutionEventRule"
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"]
  }

  statement {
    #checkov:skip=CKV_AWS_111 -- Step Functions logging delivery APIs require wildcard resource access.
    sid    = "AllowExecutionLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:DeleteLogDelivery",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
    ]
    resources = ["*"]
  }

  statement {
    #checkov:skip=CKV_AWS_111 -- X-Ray APIs require wildcard resource access.
    sid    = "AllowXrayTracing"
    effect = "Allow"
    actions = [
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:PutTelemetryRecords",
      "xray:PutTraceSegments",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "step_functions_common" {
  name   = "${local.application_name}-step-functions-common"
  role   = aws_iam_role.step_functions_common.id
  policy = data.aws_iam_policy_document.step_functions_common.json
}