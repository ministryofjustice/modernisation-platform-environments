#########################################
# CoatGithubActionsReportsUpload
#########################################
resource "aws_iam_role" "coat_github_actions_report_upload" {
  name = "CoatGithubActionsReportUpload"
  assume_role_policy = templatefile("${path.module}/templates/coat-gh-actions-assume-role-policy.json",
    {
      gh_actions_oidc_provider     = "token.actions.githubusercontent.com"
      gh_actions_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
    }
  )
}

resource "aws_iam_policy" "coat_gh_actions_policy" {
  name = "GitHubActionsUploadPolicy"
  policy = templatefile("${path.module}/templates/coat-gh-actions-policy.json",
    {
      environment = local.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "coat_github_actions_report_upload_attachment" {
  role       = aws_iam_role.coat_github_actions_report_upload.name
  policy_arn = aws_iam_policy.coat_gh_actions_policy.arn
}

#COAT Cross account role policies
resource "aws_iam_role" "coat_cross_account_role" {
  name               = "moj-coat-${local.environment}-cur-reports-cross-role"
  assume_role_policy = templatefile("${path.module}/templates/coat-cross-account-assume-role-policy.json", {})
}

resource "aws_iam_policy" "coat_cross_account_policy" {
  name = "moj-coat-${local.environment}-cur-reports-cross-role-policy"
  policy = templatefile("${path.module}/templates/coat-cross-account-policy.json",
    {
      environment = local.cross_environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "coat_cross_account_attachment" {
  role       = aws_iam_role.coat_cross_account_role.name
  policy_arn = aws_iam_policy.coat_cross_account_policy.arn
}
