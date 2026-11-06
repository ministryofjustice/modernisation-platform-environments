resource "aws_ecr_repository" "dms_seed" {
  count = local.dms_core_enabled ? 1 : 0

  name                 = "${local.application_name}-${local.environment}-${local.component_name}-seed"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_kms_key.general_shared.arn
  }

  tags = merge(
    local.tags,
    {
      Name    = "${local.application_name}-${local.environment}-${local.component_name}-seed"
      Purpose = "DMS integration test database seed image"
    }
  )
}

resource "aws_ecr_lifecycle_policy" "dms_seed" {
  count = local.dms_core_enabled ? 1 : 0

  repository = aws_ecr_repository.dms_seed[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire old integration-test seed images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}