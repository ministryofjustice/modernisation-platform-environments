####################
# Secrets Rotator
####################

resource "aws_iam_role" "ci_secrets_rotator" {
  count              = local.is-production || local.is-preproduction ? 1 : 0
  name               = "ci-secrets-rotator"
  assume_role_policy = data.aws_iam_policy_document.ci_secrets_rotator_role.json
  tags               = local.tags
}

locals {
  iaps_ds_arn              = "arn:aws:ds:eu-west-2:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.active_directory.id}"
  iaps_ds_admin_secret_arn = aws_secretsmanager_secret.ad_password.arn
}

data "aws_iam_policy_document" "ci_secrets_rotator_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:ministryofjustice/modernisation-platform-configuration-management:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}
# checkov:skip=CKV_AWS_111:ignore - Ensure IAM policies does not allow write access without constraints
# checkov:skip=CKV_AWS_356:policy requires all resources to be allowed
data "aws_iam_policy_document" "ci_secrets_rotator" {
  statement {
    sid    = "RotateSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:RotateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      local.iaps_ds_admin_secret_arn
    ]
  }
  statement {
    sid    = "ResetDSUserPassword"
    effect = "Allow"
    actions = [
      "ds:ResetUserPassword",
      "ds:DescribeDirectories"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "ci_secrets_rotator" {
  count       = local.is-production || local.is-preproduction ? 1 : 0
  name        = "ci_secrets_rotator"
  description = "Allows rotating secrets in the DS"
  policy      = data.aws_iam_policy_document.ci_secrets_rotator.json
}

resource "aws_iam_role_policy_attachment" "ci_secrets_rotator" {
  count      = local.is-production || local.is-preproduction ? 1 : 0
  policy_arn = aws_iam_policy.ci_secrets_rotator[0].arn
  role       = aws_iam_role.ci_secrets_rotator[0].name
}

####################
# CI Data Refresher
####################

resource "aws_iam_role" "ci_data_refresher" {
  count              = local.is-production || local.is-preproduction ? 1 : 0
  name               = "ci-data-refresher"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ci_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:ministryofjustice/modernisation-platform-configuration-management:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

locals {
  iaps_rds_snapshot_arn_pattern_prod    = "arn:aws:rds:${data.aws_region.current.region}:${local.environment_management.account_ids["delius-iaps-production"]}:snapshot:*iaps-*"
  iaps_rds_snapshot_arn_pattern_preprod = "arn:aws:rds:${data.aws_region.current.region}:${local.environment_management.account_ids["delius-iaps-preproduction"]}:snapshot:*iaps-*"
}

# checkov:skip=CKV_AWS_111: "policy exception"
# checkov:skip=CKV_AWS_356: "policy exception"
# checkov:skip=CKV_AWS_109: "policy exception"
data "aws_iam_policy_document" "snapshot_sharer" {
  statement {
    sid    = "CopyAndShareSnapshots"
    effect = "Allow"
    actions = [
      "rds:CopyDBSnapshot",
      "rds:DescribeDBSnapshots",
      "rds:ModifyDBSnapshotAttribute"
    ]
    resources = [
      local.iaps_rds_snapshot_arn_pattern_preprod,
      local.iaps_rds_snapshot_arn_pattern_prod,
      aws_db_instance.iaps.arn
    ]
  }

  statement {
    sid    = "AllowSSMUsage"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:DescribeParameters"
    ]
    resources = [
      aws_ssm_parameter.iaps_snapshot_data_refresh_id.arn
    ]
  }

  statement {
    sid    = "AllowKMSUsage"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "snapshot_sharer" {
  count       = local.is-production || local.is-preproduction ? 1 : 0
  name        = "snapshot_sharer"
  description = "Allows sharing of RDS snapshots"
  policy      = data.aws_iam_policy_document.snapshot_sharer.json
}

resource "aws_iam_role_policy_attachment" "ci_data_refresher" {
  count      = local.is-production || local.is-preproduction ? 1 : 0
  policy_arn = aws_iam_policy.snapshot_sharer[0].arn
  role       = aws_iam_role.ci_data_refresher[0].name
}
