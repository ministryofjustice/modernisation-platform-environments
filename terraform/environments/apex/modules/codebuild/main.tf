######################################################
# ECR Resources
######################################################

resource "aws_ecr_repository" "local-ecr" {
  name                 = "${var.app_name}-local-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-local-ecr"
    },
  )
}

resource "aws_ecr_repository_policy" "local-ecr-policy" {
  repository = aws_ecr_repository.local-ecr.name
  policy     = data.aws_iam_policy_document.local-ecr-policy-data.json
}

data "aws_iam_policy_document" "local-ecr-policy-data" {
  statement {
    sid    = "AccessECR"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${var.app_name}-CodeBuildRole", "arn:aws:iam::${var.account_id}:user/cicd-member-user"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages"
    ]
  }
}

######################################################
# CodeBuild projects
######################################################

resource "aws_iam_role" "codebuild_s3" {
  name               = "${var.app_name}-CodeBuildRole"
  assume_role_policy = file("${path.module}/codebuild_iam_role.json")
  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-CodeBuildRole"
    }
  )
}