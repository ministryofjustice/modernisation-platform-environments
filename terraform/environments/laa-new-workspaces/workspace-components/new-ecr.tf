##############################################
### ECR Repositories for LinOTP 3.x + FreeRADIUS ECS images
##############################################

resource "aws_ecr_repository" "linotp3" {
  name                 = "${local.application_name}/linotp3"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/linotp3" }
  )
}

resource "aws_ecr_lifecycle_policy" "linotp3" {
  repository = aws_ecr_repository.linotp3.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_repository" "freeradius_linotp" {
  name                 = "${local.application_name}/freeradius-linotp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/freeradius-linotp" }
  )
}

resource "aws_ecr_lifecycle_policy" "freeradius_linotp" {
  repository = aws_ecr_repository.freeradius_linotp.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
