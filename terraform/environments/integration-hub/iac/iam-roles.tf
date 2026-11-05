data "aws_iam_openid_connect_provider" "github" {
  count = local.is-production ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "pagerduty_assume_role" {
  count = local.is-production ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.pagerduty_oidc_subject]
    }
  }
}

resource "aws_iam_role" "pagerduty" {
  count = local.is-production ? 1 : 0

  name               = local.pagerduty_role_name
  path               = "/github-actions/"
  assume_role_policy = data.aws_iam_policy_document.pagerduty_assume_role[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "pagerduty_permissions" {
  count = local.is-production ? 1 : 0

  statement {
    sid       = "ListPagerDutyStatePrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.pagerduty_state_bucket[0].s3_bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        local.pagerduty_state_key,
        "${local.pagerduty_state_key}.tflock"
      ]
    }
  }

  statement {
    sid       = "GetStateBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.pagerduty_state_bucket[0].s3_bucket_arn]
  }

  statement {
    sid     = "ReadWritePagerDutyState"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [
      "${module.pagerduty_state_bucket[0].s3_bucket_arn}/${local.pagerduty_state_key}"
    ]
  }

  statement {
    sid     = "ManagePagerDutyStateLock"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${module.pagerduty_state_bucket[0].s3_bucket_arn}/${local.pagerduty_state_key}.tflock"
    ]
  }

  statement {
    sid    = "UsePagerDutyStateKmsKeyThroughS3"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.pagerduty_state_kms[0].key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [module.pagerduty_state_bucket[0].s3_bucket_arn]
    }
  }

  statement {
    sid       = "ReadPagerDutyApiToken"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.pagerduty_api_key_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "pagerduty" {
  count = local.is-production ? 1 : 0

  name   = local.pagerduty_role_name
  role   = aws_iam_role.pagerduty[0].id
  policy = data.aws_iam_policy_document.pagerduty_permissions[0].json
}
