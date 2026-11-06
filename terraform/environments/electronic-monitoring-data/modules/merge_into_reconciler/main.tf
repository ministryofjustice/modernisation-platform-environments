data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "merge_into_this" {
  source       = "../step_function"
  name         = "merge_into_${local.name}"
  iam_policies = tomap({ "merge_into_${local.name}_step_function_policy" = aws_iam_policy.merge_into_this })
  variable_dictionary = tomap(
    {
      "merge_function_name"     = var.function_to_iterate.lambda_function_arn,
      "table_name"              = local.camel_name,
      "planner_function_name"   = var.planner_function_arn,
      "reconciliation_consumer" = var.reconciliation_consumer
    }
  )
  type = "STANDARD"
}

data "aws_iam_policy_document" "merge_into_this" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = compact([
      var.function_to_iterate.lambda_function_arn,
      var.planner_function_arn,
    ])
  }

  dynamic "statement" {
    for_each = var.reconciliation_state_prefix_arn != "" ? [1] : []

    content {
      effect  = "Allow"
      actions = ["s3:GetObject"]
      resources = [
        "${var.reconciliation_state_prefix_arn}/*",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.reconciliation_consumer != "" ? [1] : []

    content {
      effect  = "Allow"
      actions = ["states:StartExecution"]
      resources = [
        "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:merge_into_${local.name}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.reconciliation_consumer != "" ? [1] : []

    content {
      effect = "Allow"
      actions = [
        "states:DescribeExecution",
        "states:StopExecution",
      ]
      resources = [
        "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:execution:merge_into_${local.name}:*",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.reconciliation_consumer != "" ? [1] : []

    content {
      effect = "Allow"
      actions = [
        "events:DescribeRule",
        "events:PutRule",
        "events:PutTargets",
      ]
      resources = [
        "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule",
      ]
    }
  }
}

resource "aws_iam_policy" "merge_into_this" {
  name   = "insert_into_${local.name}"
  policy = data.aws_iam_policy_document.merge_into_this.json
}
