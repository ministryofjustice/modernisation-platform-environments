
# Create a role
resource "aws_iam_role" "github_actions" {
  name               = "github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::348456244381:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/modernisation-platform-environments:*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "read_only" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Add actions missing from arn:aws:iam::aws:policy/ReadOnlyAccess
resource "aws_iam_policy" "extra_permissions" {
  name        = "github-actions"
  path        = "/"
  description = "A policy for extra permissions for GitHub Actions"

  policy = data.aws_iam_policy_document.extra_permissions.json
}

data "aws_iam_policy_document" "extra_permissions" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "account:GetAlternateContact",
      "cur:DescribeReportDefinitions",
      "identitystore:ListGroups",
      "secretsmanager:GetSecretValue",
      "sts:AssumeRole",
      "s3:*",
      "kms:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "extra_permissions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.extra_permissions.arn
}
