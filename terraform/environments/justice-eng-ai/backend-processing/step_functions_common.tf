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

data "aws_iam_policy_document" "script_runner_common" {
  statement {
    sid       = "AuthenticateToEcr"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PullForgeRuntimeBaseImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.region}:${local.environment_management.account_ids["core-shared-services-production"]}:repository/${local.application_data.accounts[local.environment].forge_runtime_base_ecr_repository_name}"]
  }

  statement {
    sid    = "PushPrototypeImagesToSharedRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.region}:${local.environment_management.account_ids["core-shared-services-production"]}:repository/${local.application_data.accounts[local.environment].ecr_repository_name}"]
  }
}

data "aws_iam_policy_document" "step_functions_upload_trigger_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.staging_bucket_root_upload.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "step_functions_upload_trigger" {
  name               = "${local.application_name}-upload-trigger"
  assume_role_policy = data.aws_iam_policy_document.step_functions_upload_trigger_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "step_functions_upload_trigger" {
  statement {
    sid       = "StartRootWorkflow"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [module.step_functions_root.arn]
  }
}

resource "aws_iam_role_policy" "step_functions_upload_trigger" {
  name   = "${local.application_name}-upload-trigger"
  role   = aws_iam_role.step_functions_upload_trigger.id
  policy = data.aws_iam_policy_document.step_functions_upload_trigger.json
}