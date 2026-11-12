data "aws_iam_openid_connect_provider" "github" {
  count = local.is-production ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
}

module "iam_role_pagerduty" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  name            = local.pagerduty_role_name
  use_name_prefix = false
  path            = "/github-actions/"

  trust_policy_permissions = {
    GitHubActionsPagerDuty = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [{
        type        = "Federated"
        identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:sub"
          values   = [local.pagerduty_oidc_subject]
        }
      ]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    ListPagerDutyStatePrefix = {
      actions   = ["s3:ListBucket"]
      resources = [module.pagerduty_state_bucket[0].s3_bucket_arn]
      condition = [{
        test     = "StringEquals"
        variable = "s3:prefix"
        values = [
          local.pagerduty_state_key,
          "${local.pagerduty_state_key}.tflock"
        ]
      }]
    }

    GetStateBucketLocation = {
      actions   = ["s3:GetBucketLocation"]
      resources = [module.pagerduty_state_bucket[0].s3_bucket_arn]
    }

    ReadWritePagerDutyState = {
      actions   = ["s3:GetObject", "s3:PutObject"]
      resources = ["${module.pagerduty_state_bucket[0].s3_bucket_arn}/${local.pagerduty_state_key}"]
    }

    ManagePagerDutyStateLock = {
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = ["${module.pagerduty_state_bucket[0].s3_bucket_arn}/${local.pagerduty_state_key}.tflock"]
    }

    UsePagerDutyStateKmsKeyThroughS3 = {
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
      resources = [module.pagerduty_state_kms[0].key_arn]
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["s3.eu-west-2.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:s3:arn"
          values   = [module.pagerduty_state_bucket[0].s3_bucket_arn]
        }
      ]
    }

    ReadPagerDutyApiToken = {
      actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
      resources = [module.pagerduty_api_key_secret[0].secret_arn]
      condition = [{
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["true"]
      }]
    }

    DecryptPagerDutyApiToken = {
      actions   = ["kms:Decrypt"]
      resources = [module.pagerduty_api_key_kms[0].key_arn]
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["secretsmanager.eu-west-2.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:SecretARN"
          values   = [module.pagerduty_api_key_secret[0].secret_arn]
        }
      ]
    }
  }

  tags = local.tags
}
