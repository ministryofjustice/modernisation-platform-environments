resource "aws_ecr_repository" "lambda_repo" {
  name = "lambdas-repo"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
