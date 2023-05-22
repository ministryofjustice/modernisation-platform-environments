resource "aws_iam_role" "ci_data_refresher" {
  count              = local.is-production ? 1 : 0
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
  iaps_rds_snapshot_arn_pattern = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*${aws_db_instance.iaps.id}-*"
}

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
      local.iaps_rds_snapshot_arn_pattern,
      aws_db_instance.iaps.arn
    ]
  }
}

resource "aws_iam_policy" "snapshot_sharer" {
  count       = local.is-production ? 1 : 0
  name        = "snapshot_sharer"
  description = "Allows sharing of RDS snapshots"
  policy      = data.aws_iam_policy_document.snapshot_sharer.json
}

resource "aws_iam_role_policy_attachment" "ci_data_refresher" {
  count      = local.is-production ? 1 : 0
  policy_arn = aws_iam_policy.snapshot_sharer[0].arn
  role       = aws_iam_role.ci_data_refresher[0].name
}
