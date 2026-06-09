data "aws_iam_policy_document" "ai_gateway" {
  statement {
    sid    = "AwsMarketplaceAccess"
    effect = "Allow"
    actions = [
      "aws-marketplace:Subscribe",
      "aws-marketplace:ViewSubscriptions"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "BedrockInferenceProfileAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"])
  }

  statement {
    sid       = "BedrockFoundationModelAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }

  statement {
    sid       = "AuditLogS3Access"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.audit_logs.s3_bucket_arn}/litellm-audit/audit_logs/*"]
  }

  statement {
    sid    = "AuditLogKMSAccess"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [module.ai_gateway_audit_logs_kms_key.key_arn]
  }

}

module "ai_gateway_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=5b962b1163790398605f2b17447cf5b6cc512237" # v6.6.1

  name_prefix = local.component_name

  policy = data.aws_iam_policy_document.ai_gateway.json
}
