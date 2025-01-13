# This ECR is used to store the image built by in https://github.com/ministryofjustice/analytical-platform-jml-report/releases

module "jml_ecr" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source = "terraform-aws-modules/ecr/aws"
   version = "2.3.0"

  repository_name = "analytical-platform-jml-report"

  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::593291632749:role/data_platform_jml_extract"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })

  tags = local.tags

}