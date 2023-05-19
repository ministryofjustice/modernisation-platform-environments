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

data "aws_iam_policy_document" "snapshot_sharer" {
  statement {
    sid    = "ListSnapshots"
    effect = "Allow"
    actions = [
      "rds:DescribeDBSnapshots"
    ]
    resources = [
      aws_db_instance.iaps.arn
    ]
  }

  statement {
    sid    = "ShareSnapshots"
    effect = "Allow"
    actions = [
      "rds:ModifyDBSnapshotAttribute"
    ]
    resources = [
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:rds:${aws_db_instance.iaps.id}-*"
    ]
  }
}

resource "aws_iam_policy" "snapshot_sharer" {
  name        = "snapshot_sharer"
  description = "Allows sharing of RDS snapshots"
  policy      = data.aws_iam_policy_document.snapshot_sharer.json
}

resource "aws_iam_role_policy_attachment" "ci_data_refresher" {
  policy_arn = aws_iam_policy.snapshot_sharer.arn
  role       = aws_iam_role.ci_data_refresher.name
}
