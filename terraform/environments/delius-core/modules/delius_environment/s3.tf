# S3 bucket to host Weblogic ALB Access logs
module "weblogic_alb_access_logs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" # v9.0.0

  bucket_name        = "${var.account_info.application_name}-${var.env_name}-weblogic-alb-access-logs"
  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_policy = local.alb_access_logs_bucket_policy

  tags = local.tags
}

# S3 bucket for hosting the terraform state of the Weblogic ECS config: https://github.com/ministryofjustice/delius-releases
module "weblogic_ecs_remote_state" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" # v9.0.0

  bucket_name        = "${var.account_info.application_name}-${var.env_name}-weblogic-ecs-remote-state"
  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_policy = local.ecs_bucket_policy

  tags = local.tags
}

locals {
  alb_access_logs_bucket_policy = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowALBAccessLogs"
          Effect = "Allow"

          Principal = {
            Service = "logdelivery.elasticloadbalancing.amazonaws.com"
          }

          Action = [
            "s3:PutObject"
          ]

          Resource = "${module.weblogic_alb_access_logs.bucket.arn}/*"
          
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            }
          }
        },
        {
          Sid    = "AllowDeveloperSSOReadAccess"
          Effect = "Allow"

          Principal = {
            AWS = "*"
          }

          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]

          Resource = [
            module.weblogic_alb_access_logs.bucket.arn,
            "${module.weblogic_alb_access_logs.bucket.arn}/*"
          ]

          Condition = {
            ArnLike = {
              "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_modernisation-platform-developer_*"
            }
          }
        }
      ]
    })
  ]

  ecs_bucket_policy = [
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
