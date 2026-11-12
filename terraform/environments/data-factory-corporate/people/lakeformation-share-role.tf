data "aws_iam_policy_document" "data_access_share_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/data-engineering-datalake-access-github-actions"
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/data-engineering-datalake-access:ref:refs/heads/*"]
    }
  }
}

resource "aws_iam_role" "analytical_platform_data_share" {
  name                 = "analytical-platform-data-production-share-role"
  max_session_duration = 43200
  assume_role_policy   = data.aws_iam_policy_document.data_access_share_assume_role.json
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "data_share_lakeformation_cross_account" {
  role       = aws_iam_role.analytical_platform_data_share.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
}

resource "aws_iam_role_policy_attachment" "data_share_lakeformation_admin" {
  role       = aws_iam_role.analytical_platform_data_share.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"
}