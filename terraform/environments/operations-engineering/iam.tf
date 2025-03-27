# GitHub repos Terraform state role

resource "aws_iam_role" "github_repos_state_role" {
  name               = "github_repos_state_role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_document.json
}

data "aws_iam_policy_document" "s3_access_policy_document" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      module.github_repos_state_bucket.s3_bucket_arn,
      "${module.github_repos_state_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "dynamodb_state_lock_policy" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:Scan"
    ]
    resources = [
      aws_dynamodb_table.github_repos_state_lock.arn
    ]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "github_role_prod_s3_access_policy"
  policy      = data.aws_iam_policy_document.s3_access_policy_document.json
}

resource "aws_iam_policy" "dynamodb_state_lock" {
  name   = "github-repos-prod-dynamodb-state-lock-policy"
  policy = data.aws_iam_policy_document.dynamodb_state_lock_policy.json
}

resource "aws_iam_role_policy_attachment" "github_role_perms_attachment" {
  role       = aws_iam_role.github_repos_state_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_state_lock_attachment" {
  role       = aws_iam_role.github_repos_state_role.name
  policy_arn = aws_iam_policy.dynamodb_state_lock.arn
}