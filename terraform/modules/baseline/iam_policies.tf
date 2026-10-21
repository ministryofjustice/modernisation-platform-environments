locals {
  iam_policies = merge(local.s3_buckets_iam_policies, var.iam_policies)
}

data "aws_iam_policy_document" "this" {
  for_each = local.iam_policies

  dynamic "statement" {
    for_each = each.value.statements

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "this" {
  for_each = local.iam_policies

  name        = each.key
  path        = each.value.path
  description = each.value.description
  policy      = data.aws_iam_policy_document.this[each.key].json

  tags = merge(local.tags, {
    Name = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "baseline_eventbridge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "baseline_invoke_aws_health_lambda" {
  count = local.baseline_enable_aws_health_lambda ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      var.baseline_aws_health_lambda_configuration.baseline_aws_health_lambda_arn
    ]
  }
}

resource "aws_iam_role_policy" "baseline_invoke_aws_health_lambda" {
  count  = local.baseline_enable_aws_health_lambda ? 1 : 0
  name   = "InvokeAWSHealthLambda"
  role   = aws_iam_role.baseline_eventbridge_invoke_lambda[count.index].id
  policy = data.aws_iam_policy_document.baseline_invoke_aws_health_lambda[count.index].json
}
