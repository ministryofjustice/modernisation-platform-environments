# KMS key for ppud pipeline
module "ppud_kms" {
  count = local.is-test ? 0 : 1

  # v4.2.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms?ref=af1d45558a6073c017a732d2273efcc733b34d0f"

  aliases               = ["ppud-pipeline-kms"]
  description           = "KMS key for PPUD pipeline resources"
  enable_default_policy = true

  key_statements = [
    {
      sid    = "AllowServiceAccess"
      effect = "Allow"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type = "Service"
          identifiers = [
            "lambda.amazonaws.com",
            "sns.amazonaws.com",
            "logs.${data.aws_region.current.region}.amazonaws.com"
          ]
        }
      ]
    }
  ]

  deletion_window_in_days = 7

  tags = merge(
    local.tags,
    {
      resource-type = "KMS Key"
    }
  )

}
