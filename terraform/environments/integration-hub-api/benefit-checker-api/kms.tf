module "kms_cloudwatch_logs" {
  count = local.create_service ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases                 = ["${local.application_name}/${local.component_name}/logs"]
  description             = "KMS key for benefit checker API CloudWatch logs"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_administrators      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  key_statements = [{
    sid = "AllowCloudWatchLogsService"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = ["*"]
    principals = [{
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }]
    condition = [{
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${local.application_name}-${local.component_name}"]
    }]
  }]
  tags = local.tags
}
