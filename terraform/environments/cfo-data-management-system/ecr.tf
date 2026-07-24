# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "${local.application_name_short}-${local.environment}-ecr"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = local.tags
}

# TO DO : Add lifecycle policy
