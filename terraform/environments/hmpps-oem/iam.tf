#####################
# DB Refresher Role #
#####################

resource "aws_iam_role" "db_refresher" {
  count              = local.is-development || local.is-test ? 1 : 0
  name               = "db-refresher"
  assume_role_policy = data.aws_iam_policy_document.db_refresher_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "db_refresher_role" {
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
      values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

data "aws_iam_policy_document" "db_refresher" {
  statement {
    sid    = "DescribeInstances"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt",
    ]
    resources = [
      data.aws_kms_key.general_shared.arn,
    ]
  }
  statement {
    sid    = "S3ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::s3-bucket20230608132808605000000001/*",
    ]
  }
}

resource "aws_iam_policy" "db_refresher" {
  count       = local.is-development || local.is-test ? 1 : 0
  name        = "db_refresher"
  description = "Allows describing of EC2 instances"
  policy      = data.aws_iam_policy_document.db_refresher.json
}

resource "aws_iam_role_policy_attachment" "db_refresher_ec2_describe" {
  count      = local.is-development || local.is-test ? 1 : 0
  role       = aws_iam_role.db_refresher[0].name
  policy_arn = aws_iam_policy.db_refresher[0].arn
}

resource "aws_iam_role_policy_attachment" "db_refresher_ssm_access" {
  count      = local.is-development || local.is-test ? 1 : 0
  role       = aws_iam_role.db_refresher[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
