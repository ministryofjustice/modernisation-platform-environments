resource "aws_iam_openid_connect_provider" "github" {
  url = "https://oidc-configuration.audit-log.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

data "aws_iam_policy_document" "github_actions_assume_role_policy_document" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider}:sub"
      values = [
        "repo:ministryofjustice/operations-engineering:*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

