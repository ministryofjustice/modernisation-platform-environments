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
