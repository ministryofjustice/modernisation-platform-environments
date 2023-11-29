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
      values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:main"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role_policy_attachment" "db_refresher_ssm_access" {
  count      = local.is-development || local.is-test ? 1 : 0
  role       = aws_iam_role.db_refresher[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
