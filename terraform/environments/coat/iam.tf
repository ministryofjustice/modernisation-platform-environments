#########################################
# CoatGithubActionsRole
#########################################
resource "aws_iam_role" "coat_github_actions_role" {
  name = "CoatGithubActionsRole"
  assume_role_policy = templatefile("${path.module}/templates/coat-gh-actions-assume-role-policy.json",
    {
      gh_actions_oidc_provider     = "token.actions.githubusercontent.com"
      gh_actions_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
    }
  )
}

resource "aws_iam_policy" "coat_gh_actions_policy" {
  name = "GitHubActionsPolicy"
  policy = templatefile("${path.module}/templates/coat-gh-actions-policy.json",
    {
      environment      = local.environment
      account          = data.aws_caller_identity.current.account_id
      region           = data.aws_region.current.name
      athena_workgroup = local.athena_workgroup
      data_catalog     = local.data_catalog
    }
  )
}

resource "aws_iam_role_policy_attachment" "coat_github_actions_attachment" {
  role       = aws_iam_role.coat_github_actions_role.name
  policy_arn = aws_iam_policy.coat_gh_actions_policy.arn
}

#COAT Cross account role policies with mp dev SSO role
resource "aws_iam_role" "coat_cross_account_role" {
  count = local.is-production ? 1 : 0
  name  = "moj-coat-${local.environment}-cur-reports-cross-role"
  assume_role_policy = templatefile("${path.module}/templates/coat-cross-account-assume-role-policy.json",
    {
      cross_account_role = "arn:aws:iam::${local.coat_prod_account_id}:role/moj-coat-${local.prod_environment}-cur-reports-cross-role"
      mp_dev_role_arn    = data.aws_iam_role.moj_mp_dev_role[0].arn
    }
  )
}

resource "aws_iam_policy" "coat_cross_account_policy" {
  count = local.is-production ? 1 : 0
  name  = "moj-coat-${local.environment}-cur-reports-cross-role-policy"
  policy = templatefile("${path.module}/templates/coat-cross-account-policy.json",
    {
      environment       = local.environment
      dev_environment   = local.dev_environment
      kms_master_key_id = local.kms_master_key_id
      kms_prod_key_id   = local.kms_prod_key_id
      kms_dev_key_id    = local.kms_dev_key_id
    }
  )
}

resource "aws_iam_role_policy_attachment" "coat_cross_account_attachment" {
  count      = local.is-production ? 1 : 0
  role       = aws_iam_role.coat_cross_account_role[0].name
  policy_arn = aws_iam_policy.coat_cross_account_policy[0].arn
}

data "aws_iam_policy_document" "greenpixie_assume_role_policy_document" {
  statement {
    sid     = "AssumeRolePolicy"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::457748205563:user/gpx-data-moj-user"]
    }
    condition {
      test     = "StringEquals"
      values   = ["gpx-data-moj-assume-id"]
      variable = "sts:ExternalId"
    }
  }
}

data "aws_iam_policy_document" "greenpixie_inline_policy_document" {
  statement {
    sid = "AccessSourceBucket"

    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*"
    ]
  }

  statement {
    sid = "AccessDestBucket"

    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*"
    ]
  }

  statement {
    sid = "KMSPermissionsForSourceAndDestBuckets"

    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*"
    ]
    resources = [module.cur_s3_kms.key_arn, local.kms_dev_key_id]
  }
}

resource "aws_iam_policy" "s3_greenpixie_read_source_write_dest_policy" {
  name   = "S3GreenPixieReadSourceWriteDestPolicy"
  policy = data.aws_iam_policy_document.greenpixie_inline_policy_document.json
}

resource "aws_iam_role" "greenpixie_data_moj_user_role" {
  name               = "GreenPixieMojUserRole"
  assume_role_policy = data.aws_iam_policy_document.greenpixie_assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "greenpixie_role_policy_attachment" {
  role       = aws_iam_role.greenpixie_data_moj_user_role.name
  policy_arn = aws_iam_policy.s3_greenpixie_read_source_write_dest_policy.arn
}

##########################################
# CUR Enriched Replication Role  #
##########################################

module "cur_v2_hourly_enriched_replication_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = local.is-development ? 0 : 1

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.60.0"

  create_role = true

  role_name         = "moj-cur-v2-hourly-enriched-replication-role"
  role_requires_mfa = false

  trusted_role_services = [
    "batchoperations.s3.amazonaws.com",
    "s3.amazonaws.com"
  ]

  custom_role_policy_arns = [module.cur_v2_hourly_enriched_replication_policy[0].arn]
}

data "aws_iam_policy_document" "cur_v2_hourly_enriched_replication" {
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.cur_v2_hourly_enriched[0].s3_bucket_arn]
  }

  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = ["${module.cur_v2_hourly_enriched[0].s3_bucket_arn}/*"]
  }

  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags"
    ]
    resources = [
      "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly-enriched",
      "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly-enriched/*"
    ]
  }

  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.cur_s3_kms.key_arn]
  }

  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:eu-west-1:593291632749:key/0409ddbc-b6a2-46c4-a613-6145f6a16215"
    ]
  }
}

module "cur_v2_hourly_enriched_replication_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = local.is-development ? 0 : 1

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"
  name    = "${module.cur_v2_hourly_enriched_replication_role[0].iam_role_name}-policy"

  policy = data.aws_iam_policy_document.cur_v2_hourly_enriched_replication.json
}