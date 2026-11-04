# GOV.UK Notify API key. Not adding a secret version as the key is issued by
# GOV.UK Notify; set the value manually in the console after the secret is created.
resource "aws_kms_key" "secrets_key" {
  description             = "AWS Secretsmanager CMK for ${local.application_name} backend processing secrets"
  policy                  = data.aws_iam_policy_document.kms_secrets_key.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
  multi_region            = true
  tags                    = local.tags
}

resource "aws_kms_alias" "secrets_key" {
  name          = "alias/${local.application_name}-backend-processing-secrets-key"
  target_key_id = aws_kms_key.secrets_key.id
}

data "aws_iam_policy_document" "kms_secrets_key" {
  # checkov:skip=CKV_AWS_109: Key policy is attached to the key itself; account root delegates access to IAM
  # checkov:skip=CKV_AWS_111: Key policy is attached to the key itself; account root delegates access to IAM
  # checkov:skip=CKV_AWS_356: Policy is attached to a resource
  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret" "gov_uk_notify_api_key" {
  # checkov:skip=CKV2_AWS_57:Auto rotation not possible, the key is issued by GOV.UK Notify
  name        = "gov_uk_notify_api_key"
  description = "API key for accessing the GOV.UK Notify service for sending email notifications"
  kms_key_id  = aws_kms_key.secrets_key.id
  tags        = local.tags
}

# Allow the script-runner ECS task role to read the secret and decrypt it
data "aws_iam_policy_document" "script_runner_gov_uk_notify_api_key" {
  statement {
    sid       = "ReadGovUkNotifyApiKey"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.gov_uk_notify_api_key.arn]
  }

  statement {
    sid       = "DecryptGovUkNotifyApiKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets_key.arn]
  }
}

resource "aws_iam_role_policy" "script_runner_gov_uk_notify_api_key" {
  name   = "${local.application_name}-script-runner-gov-uk-notify-api-key"
  role   = aws_iam_role.script_runner_ecs_task.name
  policy = data.aws_iam_policy_document.script_runner_gov_uk_notify_api_key.json
}
