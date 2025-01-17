locals {
  oidc_provider = "token.actions.githubusercontent.com"
  account_id    = local.environment_management.account_ids[terraform.workspace]
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

resource "aws_iam_role" "cloudtrail_query_role" {
  name               = "cloudtrail_query_role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_document.json
}

resource "aws_iam_policy" "cloudtrail_query_policy" {
  name        = "cloudtrail_query_policy"
  description = "Policy to query CloudTrail Data Lake"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudtrail:LookupEvents",
          "cloudtrail:StartQuery",
          "cloudtrail:GetQueryResults"
        ],
        #checkov:skip=CKV_AWS_290:Cannot not define specific resources for cloudtrail
        #checkov:skip=CKV_AWS_355:Cannot not define specific resources for cloudtrail
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_query_policy_attachment" {
  role       = aws_iam_role.cloudtrail_query_role.name
  policy_arn = aws_iam_policy.cloudtrail_query_policy.arn
}
