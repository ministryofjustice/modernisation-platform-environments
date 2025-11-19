data "aws_iam_policy_document" "ap_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/data-engineering-datalake-access-github-actions"]
    }
  }
}

resource "aws_iam_role" "analytical_platform_share_role" {
  name = "lakeformation-share-role"

  assume_role_policy = data.aws_iam_policy_document.ap_assume_role.json
}

# ref: https://docs.aws.amazon.com/lake-formation/latest/dg/cross-account-prereqs.html
resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment" {
  role       = aws_iam_role.analytical_platform_share_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
}

data "aws_iam_policy_document" "lakeformation_share_permissions_policy" {
  statement {
    effect  = "Allow"
    actions = ["iam:GetRole"]
    resources = ["arn:aws:iam::*:role/lakeformation-share-role"]
  }
}

resource "aws_iam_role_policy" "lakeformation_share_permissions_policy" {
  name   = "lakeformation-share-permissions-policy"
  role   = aws_iam_role.analytical_platform_share_role.id
  policy = data.aws_iam_policy_document.lakeformation_share_permissions_policy.json
}
