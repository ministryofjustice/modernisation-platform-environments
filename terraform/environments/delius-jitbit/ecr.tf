# Create an ECR to hold docker images for the jitbit app

#tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "jitbit_app_ecr_repo" {
  # checkov:skip=CKV_AWS_136

  name                 = "jitbit-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}
