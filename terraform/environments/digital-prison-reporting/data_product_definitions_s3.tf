locals {
  definitions_bucket_name = "${local.project}-data-product-definitions-${local.env}"
  dpd_publishing_teams = {
    activities = {
      github_repo      = "hmpps-dpr-activities-dpds"
      s3_prefix        = "activities"
    }
  }
}

module "s3_data_product_definitions_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = local.definitions_bucket_name
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false
  enable_lifecycle          = false
  enable_s3_versioning      = true
  enable_versioning_config  = "Enabled"
  enable_intelligent_tiering = false

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-data-product-definitions-${local.env}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "PDHD-227"
    }
  )
}

data "aws_iam_policy_document" "dpd_s3_publisher_assume_role_policy" {
  for_each = local.dpd_publishing_teams

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test = "StringLike"
      values = [
        "repo:ministryofjustice/${each.value.github_repo}:environment:${local.env}"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
  }
}

resource "aws_iam_role" "dpd_s3_publisher_role" {
  for_each = local.dpd_publishing_teams

  name = "${local.project}-dpd-s3-publisher-${each.key}-${local.env}"

  assume_role_policy = data.aws_iam_policy_document.dpd_s3_publisher_assume_role_policy[each.key].json

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-dpd-s3-publisher-${each.key}-${local.env}"
      dpr-resource-type = "IAM Role"
      dpr-jira          = "PDHD-228"
    }
  )
}

data "aws_iam_policy_document" "dpd_s3_publisher_policy" {
  for_each = local.dpd_publishing_teams

  statement {
    sid    = "ListOwnDPDPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      module.s3_data_product_definitions_bucket.bucket_arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "${each.value.s3_prefix}",
        "${each.value.s3_prefix}/*"
      ]
    }
  }

  statement {
    sid    = "ReadWriteOwnDPDPrefix"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${module.s3_data_product_definitions_bucket.bucket_arn}/${each.value.s3_prefix}/*"
    ]
  }

  statement {
    sid    = "UseKmsForDPDBucketObjects"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = [
      local.s3_kms_arn
    ]
  }
}

resource "aws_iam_policy" "dpd_s3_publisher_policy" {
  for_each = local.dpd_publishing_teams

  name        = "${local.project}-dpd-s3-publisher-${each.key}-${local.env}"
  description = "Allows ${each.key} to publish DPD JSON files to their S3 prefix"
  policy      = data.aws_iam_policy_document.dpd_s3_publisher_policy[each.key].json
}

resource "aws_iam_role_policy_attachment" "dpd_s3_publisher_policy" {
  for_each = local.dpd_publishing_teams

  policy_arn = aws_iam_policy.dpd_s3_publisher_policy[each.key].arn
  role       = aws_iam_role.dpd_s3_publisher_role[each.key].name
}