resource "aws_iam_role" "ci_data_refresher" {
  count = local.environment == "production" ? 1 : 0
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
