resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = var.iam_role.arn
  definition = jsondecode(templatefile("step_function_definitions/${var.name}.json.tmpl"), var.variable_dict)
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