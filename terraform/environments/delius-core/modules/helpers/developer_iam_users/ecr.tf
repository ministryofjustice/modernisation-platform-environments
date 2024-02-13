##################################################
# ECR Push User
##################################################

data "aws_iam_policy_document" "developer_ecr_push" {
  count = var.ecr_push_user ? 1 : 0
  statement {
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user" "developer_ecr_push" {
  count = var.ecr_push_user ? 1 : 0
  name  = "delius-developer-ecr-push"
}

resource "aws_iam_user_policy" "developer_ecr_push" {
  count  = var.ecr_push_user ? 1 : 0
  name   = "delius-developer-ecr-push-policy"
  user   = aws_iam_user.developer_ecr_push[0].name
  policy = data.aws_iam_policy_document.developer_ecr_push[0].json
}

resource "aws_iam_access_key" "developer_ecr_push" {
  count = var.ecr_push_user ? 1 : 0
  user  = aws_iam_user.developer_ecr_push[0].name
}

resource "aws_secretsmanager_secret" "developer_ecr_push" {
  count = var.ecr_push_user ? 1 : 0
  name  = "delius-developer-ecr-push"
}

resource "aws_secretsmanager_secret_version" "developer_ecr_push" {
  count     = var.ecr_push_user ? 1 : 0
  secret_id = aws_secretsmanager_secret.developer_ecr_push[0].id
  secret_string = jsonencode({
    "access_key" = aws_iam_access_key.developer_ecr_push[0].id,
    "secret_key" = aws_iam_access_key.developer_ecr_push[0].secret
  })
}

##################################################
# ECR Pull User
##################################################

data "aws_iam_policy_document" "developer_ecr_pull" {
  count = var.ecr_pull_user ? 1 : 0
  statement {
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user" "developer_ecr_pull" {
  count = var.ecr_pull_user ? 1 : 0
  name  = "delius-developer-ecr-pull"
}

resource "aws_iam_user_policy" "developer_ecr_pull" {
  count  = var.ecr_pull_user ? 1 : 0
  name   = "delius-developer-ecr-pull-policy"
  user   = aws_iam_user.developer_ecr_pull[0].name
  policy = data.aws_iam_policy_document.developer_ecr_push[0].json
}

resource "aws_iam_access_key" "developer_ecr_pull" {
  count = var.ecr_pull_user ? 1 : 0
  user  = aws_iam_user.developer_ecr_pull[0].name
}

resource "aws_secretsmanager_secret" "developer_ecr_pull" {
  count = var.ecr_pull_user ? 1 : 0
  name  = "delius-developer-ecr-pull"
}

resource "aws_secretsmanager_secret_version" "developer_ecr_pull" {
  count     = var.ecr_pull_user ? 1 : 0
  secret_id = aws_secretsmanager_secret.developer_ecr_pull[0].id
  secret_string = jsonencode({
    "access_key" = aws_iam_access_key.developer_ecr_pull[0].id,
    "secret_key" = aws_iam_access_key.developer_ecr_pull[0].secret
  })
}