# ---------------------------------------------------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecr_repository" "repository" {
  for_each             = local.ecr_repositories
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_kms_key.general_shared.arn
  }

  tags = local.extended_tags
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each   = local.ecr_repositories
  repository = aws_ecr_repository.repository[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep latest tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep most recent semantic version"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Expire all other images older than 7 days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })
}

data "aws_iam_policy_document" "ecr_policy_document" {
  statement {
    sid    = "AllowECSPull"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  for_each   = local.ecr_repositories
  repository = aws_ecr_repository.repository[each.key].name
  policy     = data.aws_iam_policy_document.ecr_policy_document.json
}
