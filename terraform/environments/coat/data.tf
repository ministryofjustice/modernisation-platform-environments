#### This file can be used to store data specific to the member account ####
#extract IAM role arn for the modernisation-platform-developer role
data "aws_iam_role" "moj_mp_dev_role" {
  count = local.is-production ? 1 : 0
  name  = local.mp_dev_role
}

#### This file can be used to store data specific to the member account ####
data "aws_iam_policy_document" "github_actions_assume_role_policy_document" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.coat_prod_account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider}:sub"
      values = [
        "repo:ministryofjustice/cloud-optimisation-and-accountability:*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}