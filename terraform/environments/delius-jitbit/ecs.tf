module "ecs-new" {
  source = "github.com/ministryofjustice/terraform-ecs//cluster?ref=4f18199b40db858581c0e21af018e1cf8575d0f3"

  environment = local.environment
  name        = format("%s-new", local.application_name)

  tags = local.tags
}

#Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-deployment"
  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

output "s3_bucket_app_deployment_name" {
  value = module.s3_bucket_app_deployment.bucket.id
}
