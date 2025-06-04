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
  role = aws_iam_role.coat_github_actions_report_upload.name
  policy_arn = aws_iam_policy.coat_gh-actions-policy.arn
}