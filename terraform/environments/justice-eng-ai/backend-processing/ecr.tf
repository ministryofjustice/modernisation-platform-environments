# Prototype images are built and stored in this account, so each environment
# (development, test, preproduction, production) has its own repository.
#tfsec:ignore:AWS078 tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "user_applications" {
  #checkov:skip=CKV_AWS_51:Tags are overwritten on rebuild, so the repository must be mutable
  #checkov:skip=CKV_AWS_136:AWS-managed KMS encryption is sufficient for prototype images
  name                 = "ai-builder-user-applications"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

data "aws_iam_policy_document" "user_applications_repository" {
  statement {
    sid    = "AllowScriptRunnerPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.script_runner_ecs_task.arn]
    }
  }
}

resource "aws_ecr_repository_policy" "user_applications" {
  repository = aws_ecr_repository.user_applications.name
  policy     = data.aws_iam_policy_document.user_applications_repository.json
}
