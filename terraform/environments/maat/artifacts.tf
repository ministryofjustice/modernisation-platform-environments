# Terraform module which creates S3 Bucket resources for Load Balancer Access Logs on AWS.

module "artifacts-s3" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-build-artifacts"
  bucket_policy       = [data.aws_iam_policy_document.arfitacts.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = true
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 31
      }

      noncurrent_version_expiration = {
        days = 31
      }
    }
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "arfitacts" {
  # statement {
  #   effect = "Allow"
  #   actions = [
  #     "s3:PutObject"
  #   ]
  #   resources = [
  #     "${module.artifacts-s3.bucket.arn}/*"
  #   ]
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::${local.env_account_id}:role/modernisation-platform-oidc-cicd"]
  #   }
  # }

}

