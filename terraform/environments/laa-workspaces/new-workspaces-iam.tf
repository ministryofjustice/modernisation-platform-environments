#############################################
### WorkSpaces IAM Roles
##############################################

data "aws_iam_policy_document" "workspaces_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workspaces_default" {
  count = local.environment == "development" ? 1 : 0

  name               = "workspaces_DefaultRole"
  assume_role_policy = data.aws_iam_policy_document.workspaces_assume_role.json

  tags = merge(
    local.tags,
    { "Name" = "workspaces_DefaultRole" }
  )
}

resource "aws_iam_role_policy_attachment" "workspaces_default_service_access" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.workspaces_default[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_default_self_service_access" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.workspaces_default[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "aws_iam_role_policy" "workspaces_ds_access" {
  count = local.environment == "development" ? 1 : 0

  name = "workspaces-directory-service-access"
  role = aws_iam_role.workspaces_default[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ds:AuthorizeApplication",
          "ds:UnauthorizeApplication",
          "ds:DescribeDirectories",
          "ds:CheckAlias",
          "ds:CreateAlias",
          "ds:DescribeTrusts",
          "ds:DeleteDirectory",
          "ds:CreateIdentityPoolDirectory",
          "ds:ListAuthorizedApplications"
        ]
        Resource = "*"
      }
    ]
  })
}

##############################################
### GitHub Actions IAM Policy for AD User Management
### Allows GitHub Actions to create/delete users in Microsoft AD
##############################################

# Policy for ds-data API access (AD user management)
resource "aws_iam_policy" "github_actions_ds_data_access" {
  count = local.environment == "development" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-github-ds-data-access"
  description = "Allow GitHub Actions to manage AD users via ds-data API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DirectoryServiceDataAccess"
        Effect = "Allow"
        Action = [
          "ds-data:CreateUser",
          "ds-data:UpdateUser",
          "ds-data:DeleteUser",
          "ds-data:DescribeUser",
          "ds-data:ListUsers"
        ]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad[0].id}"
      },
      {
        Sid    = "DirectoryServiceAccess"
        Effect = "Allow"
        Action = [
          "ds:AccessDSData"
        ]
        Resource = "arn:aws:ds:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:directory/${aws_directory_service_directory.workspaces_ad[0].id}"
      }
    ]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-github-ds-data-access" }
  )
}

# Attach policy to GitHub Actions apply role
resource "aws_iam_role_policy_attachment" "github_actions_ds_data_access" {
  count = local.environment == "development" ? 1 : 0

  role       = "github-actions-apply"
  policy_arn = aws_iam_policy.github_actions_ds_data_access[0].arn
}

# IAM policy for GitHub Actions to send SSM commands during deployment
resource "aws_iam_policy" "github_actions_ssm_access" {
  count = local.environment == "development" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-github-ssm-access"
  description = "Allow GitHub Actions to send SSM commands for user creation EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ]
        Resource = [
          "arn:aws:ec2:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${local.application_data.accounts[local.environment].region}::document/AWS-RunPowerShellScript"
        ]
      }
    ]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-github-ssm-access" }
  )
}

resource "aws_iam_role_policy_attachment" "github_actions_ssm_access" {
  count = local.environment == "development" ? 1 : 0

  role       = "github-actions-apply"
  policy_arn = aws_iam_policy.github_actions_ssm_access[0].arn
}
