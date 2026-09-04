module "kms_cloudwatch_logs" {
  #checkov:skip=CKV_TF_1:Terraform Registry modules are version-pinned and do not support commit hash references
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.1"

  aliases                 = ["integration-hub/logs/${local.resource_application_name}"]
  description             = "KMS key for downstream mock API CloudWatch Logs encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${var.account_id}:root"]

  key_statements = [
    {
      sid = "AllowCloudWatchLogsService"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["logs.${var.region}.amazonaws.com"]
      }]
      condition = [{
        test     = "ArnEquals"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values = [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/apigateway/${local.resource_name_prefix}",
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/ecs/${local.resource_name_prefix}"
        ]
      }]
    },
    {
      sid       = "AllowCloudWatchLogsAssociationCallers"
      actions   = ["kms:DescribeKey"]
      resources = ["*"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_id}:role/github-actions-apply",
          "arn:aws:iam::${var.account_id}:role/github-actions-plan",
          "arn:aws:iam::${var.account_id}:role/MemberInfrastructureAccess"
        ]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["logs.${var.region}.amazonaws.com"]
      }]
    },
    {
      sid = "AllowPlatformUsersToReadEncryptedLogs"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]
      condition = [
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values = [
            "arn:aws:iam::${var.account_id}:role/MemberInfrastructureAccess",
            "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/${var.region}/AWSReservedSSO_*"
          ]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logs.${var.region}.amazonaws.com"]
        }
      ]
    }
  ]

  tags = local.tags
}
