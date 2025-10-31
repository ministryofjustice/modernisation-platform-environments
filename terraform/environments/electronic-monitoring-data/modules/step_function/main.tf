data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_sfn_state_machine" "this" {
  name       = var.name
  role_arn   = aws_iam_role.step_function_role.arn
  definition = templatefile("step_function_definitions/${var.name}.json.tmpl", var.variable_dictionary)
  type       = var.type
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.this_log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
  tracing_configuration {
    enabled = true
  }
}

resource "aws_iam_role" "step_function_role" {
  name               = "${var.name}_step_function_role"
  assume_role_policy = data.aws_iam_policy_document.assume_step_function.json
}

resource "aws_iam_role_policy_attachment" "this_attachment" {
  for_each   = var.iam_policies
  role       = aws_iam_role.step_function_role.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "base_perms_attached" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_base_permissions.arn
}

data "aws_iam_policy_document" "assume_step_function" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "step_function_base_permissions" {
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_111
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish", "sqs:SendMessage"]
    resources = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [aws_kms_key.this_log_key.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:PutDestination",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:PutDestinationPolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "step_function_base_permissions" {
  name   = "step_function_base_permissions_${var.name}"
  policy = data.aws_iam_policy_document.step_function_base_permissions.json
}

# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "this_log_key_document" {
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
  }

  statement {
    sid    = "EnableLogServicePermissions"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
  }
}

resource "aws_kms_key" "this_log_key" {
  description         = "KMS key for encrypting Step Function ${var.name} logs"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.this_log_key_document.json
}

resource "aws_cloudwatch_log_group" "this_log_group" {
  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.this_log_key.arn
}
