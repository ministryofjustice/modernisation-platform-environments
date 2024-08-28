resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.step_function_role.arn
  definition = templatefile("step_function_definitions/${var.name}.json.tmpl", var.variable_dictionary)
}

resource "aws_iam_role" "step_function_role" {
    name = "${var.name}_step_function_role"
    assume_role_policy = data.aws_iam_policy_document.assume_step_function.json
}

resource "aws_iam_role_policy_attachment" "this_attachment" {
    for_each = var.iam_policies

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
    actions   = ["sts:AssumeRole"]
    }
}

data "aws_iam_policy_document" "step_function_base_permissions" {
    statement {
        effect = "Allow"
        actions   = [
            "sns:Publish",
            "sqs:SendMessage"
            ]
        resources = ["*"]
    }
}

resource "aws_iam_policy" "step_function_base_permissions" {
    name = "step_function_base_permissions"
    policy = data.aws_iam_policy_document.step_function_base_permissions.json
}

data "aws_iam_policy_document" "this_log_key_document" {
    statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.env_account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
    }

    statement {
    sid    = "EnableLogServicePermissions"
    effect = "Allow"
    principals {
        type        = "Service"
        identifiers = ["logs.eu-west-2.amazonaws.com"]
    }
    actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
    ]
    resources = ["*"]
    }
}


resource "aws_kms_key_policy" "kms_key_policy" {
    key_id = aws_kms_key.this_log_key.id
    policy = data.aws_iam_policy_document.this_log_key_document
}

resource "aws_kms_key" "this_log_key" {
    description         = "KMS key for encrypting Step Functions logs"
    enable_key_rotation = true
}

resource "aws_cloudwatch_log_group" "this_log_group" {
  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.this_log_key.arn
}