resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

locals {
    branch = local.is-production ? "main": "*"
}

data "aws_iam_policy_document" "ecr_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/electronic-monitoring-data-lambda-functions:ref:refs/heads/${local.branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "GitHubActionsECRRole"
  assume_role_policy = data.aws_iam_policy_document.ecr_assume_role_policy.json
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "ECRPushPolicy"
  description = "Policy to allow pushing Docker images to ECR"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}

resource "aws_iam_role_policy_attachment" "gh_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}
