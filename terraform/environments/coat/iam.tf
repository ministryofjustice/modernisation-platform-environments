#########################################
# CoatGithubActionsS3ReportsUpload
#########################################
resource "aws_iam_role" "coat_github_actions_s3_reports_upload" {
  name               = "CoatGithubActionsS3ReportsUpload"
  assume_role_policy = data.aws_iam_policy_document.coat_github_actions_upload_reports_s3.json
}

data "aws_iam_policy_document" "coat_github_actions_upload_reports_s3" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/cloud-optimisation-and-accountability:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role_policy" "coat_github_actions_s3_upload" {
  name   = "GitHubActionsS3UploadPolicy"
  role   = aws_iam_role.coat_github_actions_s3_reports_upload.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { 
        Sid      = "ReadWriteToReportsFolder",
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::coat-reports${local.environment}/*"
      },
      {
        Sid      = "ListReportsBucket",
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::coat-reports${local.environment}"
      }
    ]
  })
}