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

#COAT Cross account role policies with mp dev SSO role
resource "aws_iam_role" "coat_cross_account_role" {
  count = local.is-development ? 1 : 0
  name  = "moj-coat-${local.environment}-cur-reports-cross-role"
  assume_role_policy = templatefile("${path.module}/templates/coat-cross-account-assume-role-policy.json",
    {
      cross_account_role = "arn:aws:iam::${local.coat_prod_account_id}:role/moj-coat-${local.prod_environment}-cur-reports-cross-role"
      mp_dev_role_arn    = data.aws_iam_role.moj_mp_dev_role[0].arn
    }
  )
}

resource "aws_iam_policy" "coat_cross_account_policy" {
  count = local.is-development ? 1 : 0
  name  = "moj-coat-${local.environment}-cur-reports-cross-role-policy"
  policy = templatefile("${path.module}/templates/coat-cross-account-policy.json",
    {
      environment = local.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "coat_cross_account_attachment" {
  count      = local.is-development ? 1 : 0
  role       = aws_iam_role.coat_cross_account_role[0].name
  policy_arn = aws_iam_policy.coat_cross_account_policy[0].arn
}

resource "aws_iam_role" "coat_cross_account_role" {
  count = local.is-production ? 1 : 0
  name  = "moj-coat-${local.environment}-cur-reports-cross-role"
  assume_role_policy = templatefile("${path.module}/templates/coat-cross-prod-assume-role-policy.json", {})
}

resource "aws_iam_policy" "coat_cross_account_policy" {
  count = local.is-production ? 1 : 0
  name  = "moj-coat-${local.environment}-cur-reports-cross-role-policy"
  policy = templatefile("${path.module}/templates/coat-cross-dev-account-policy.json",
    {
      cross_account_role = "arn:aws:iam::${local.coat_dev_account_id}:role/moj-coat-${local.dev_environment}-cur-reports-cross-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "coat_cross_account_attachment" {
  count      = local.is-production ? 1 : 0
  role       = aws_iam_role.coat_cross_account_role[0].name
  policy_arn = aws_iam_policy.coat_cross_account_policy[0].arn
}
