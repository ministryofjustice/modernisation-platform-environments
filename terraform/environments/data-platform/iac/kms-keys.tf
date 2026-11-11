module "kms_key" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=926e8c8aac77189686262b6f95e8e6bedcc9acfa" # v4.1.1

  aliases               = ["s3/mojdp-${local.environment}-${local.component_name}"]
  enable_default_policy = true

  key_statements = [
    {
      sid    = "AllowDataPlatformEngineers"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      condition = [
        {
          test     = "ForAnyValue:StringLike"
          variable = "aws:PrincipalArn"
          values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*"]
        },
        {
          test     = "StringEquals"
          variable = "aws:PrincipalAccount"
          values   = [local.environment_management.account_ids["data-platform-development"]]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "kms_key_dp_prod" {
  count = terraform.workspace == "data-platform-production" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=926e8c8aac77189686262b6f95e8e6bedcc9acfa" # v4.1.1

  aliases               = ["s3/mojdp-${local.environment}-${local.component_name}"]
  enable_default_policy = true

  key_statements = [
    {
      sid    = "AllowDataPlatformEngineers"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      condition = [
        {
          test     = "ForAnyValue:StringLike"
          variable = "aws:PrincipalArn"
          values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*"]
        },
        {
          test     = "StringEquals"
          variable = "aws:PrincipalAccount"
          values   = [local.environment_management.account_ids["data-platform-production"]]
        }
      ]
    },
    {
      sid    = "AllowOpenAIManagement"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      # The role ARN is constructed rather than referenced from the module output, as
      # the role's inline policy depends on this key and would otherwise create a cycle.
      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:PrincipalArn"
          values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions/openai-management"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "octo_kms_key" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=926e8c8aac77189686262b6f95e8e6bedcc9acfa" # v4.1.1

  aliases               = ["s3/mojdp-${local.environment}-${local.component_name}-octo"]
  enable_default_policy = true

  key_statements = [
    {
      sid    = "AllowDataPlatformEngineers"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      condition = [
        {
          test     = "ForAnyValue:StringLike"
          variable = "aws:PrincipalArn"
          values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*"]
        },
        {
          test     = "StringEquals"
          variable = "aws:PrincipalAccount"
          values   = [local.environment_management.account_ids["data-platform-development"]]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}
