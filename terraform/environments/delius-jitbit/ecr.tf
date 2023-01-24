# Create an ECR to hold docker images for the jitbit app
resource "aws_ecr_repository" "jitbit_app_ecr_repo" {
  name                 = "jitbit-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}