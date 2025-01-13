# This ECR is used to store the image built by in https://github.com/ministryofjustice/analytical-platform-jml-report/releases

module "jml-ecr" {
  source = "terraform-aws-modules/ecr/aws"
   version = "2.3.0"

  repository_name = "jml-report-ecr"

  # repository_lambda_read_access_arns = []
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 10 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}