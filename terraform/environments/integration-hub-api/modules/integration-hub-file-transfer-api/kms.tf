module "kms_cloudwatch_logs" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["integration-hub-api/logs/${local.component_name}"]
  description             = "KMS CMK for Integration Hub API CloudWatch Logs encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${local.account_id}:root"]

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
        identifiers = ["logs.${local.region}.amazonaws.com"]
      }]
      condition = [{
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"]
      }]
    },
    {
      sid       = "AllowCloudWatchLogsAssociationCallers"
      actions   = ["kms:DescribeKey"]
      resources = ["*"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.account_id}:role/github-actions-apply",
          "arn:aws:iam::${local.account_id}:role/github-actions-plan",
          "arn:aws:iam::${local.account_id}:role/MemberInfrastructureAccess",
        ]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["logs.${local.region}.amazonaws.com"]
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
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
            "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/${local.region}/AWSReservedSSO_*",
          ]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logs.${local.region}.amazonaws.com"]
        }
      ]
    }
  ]

  tags = var.tags
}