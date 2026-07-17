# S3 bucket for hosting the terraform state of the Weblogic ECS config: https://github.com/ministryofjustice/delius-releases
module "weblogic_ecs_remote_state" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" # v9.0.0

  bucket_name        = "${var.account_info.application_name}-${var.env_name}-weblogic-ecs-remote-state"
  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

locals{
  bucket_policy = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowTerraformStateBucketListing"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/modernisation-platform-oidc-cicd"
          }
          Action = [
            "s3:ListBucket"
          ]
          Resource = "arn:aws:s3:::${var.account_info.application_name}-${var.env_name}-weblogic-ecs-remote-state"
          Condition = {
            StringLike = {
              "s3:prefix" = [
                "weblogic-ecs/*"
              ]
            }
          }
        },
        {
          Sid    = "AllowTerraformStateReadWrite"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/modernisation-platform-oidc-cicd"
          }
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
          ]
          Resource = [
            "arn:aws:s3:::${var.account_info.application_name}-${var.env_name}-weblogic-ecs-remote-state/*"
          ]
        }
      ]
    })
  ]
}