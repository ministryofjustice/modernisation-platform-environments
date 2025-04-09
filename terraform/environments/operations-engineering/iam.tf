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
      module.github_repos_tfstate_bucket.s3_bucket_arn,
      "${module.github_repos_tfstate_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "github_role_prod_s3_access_policy"
  policy = data.aws_iam_policy_document.s3_access_policy_document.json
}

resource "aws_iam_role_policy_attachment" "github_role_perms_attachment" {
  role       = aws_iam_role.github_repos_state_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


# Auth0 Terraform state role

resource "aws_iam_role" "auth0_tfstate_role" {
  name               = "auth0_tfstate_role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_document.json
}

data "aws_iam_policy_document" "auth0_s3_access_policy_document" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      module.auth0_tfstate_bucket.s3_bucket_arn,
      "${module.auth0_tfstate_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "auth0_s3_access_policy" {
  name   = "auth0_role_prod_s3_access_policy"
  policy = data.aws_iam_policy_document.auth0_s3_access_policy_document.json
}

resource "aws_iam_role_policy_attachment" "auth0_role_perms_attachment" {
  role       = aws_iam_role.auth0_tfstate_role.name
  policy_arn = aws_iam_policy.auth0_s3_access_policy.arn
}
