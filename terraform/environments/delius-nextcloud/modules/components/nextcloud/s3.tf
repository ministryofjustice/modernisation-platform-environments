module "s3_bucket_config" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_name     = "${var.env_name}-config"
  versioning_enabled = true
  sse_algorithm      = "AES256"
  # Useful guide - https://aws.amazon.com/blogs/storage/how-to-use-aws-datasync-to-migrate-data-between-amazon-s3-buckets/
  bucket_policy_v2 = [{
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    principals = {
      type = "AWS"
      identifiers = [
          module.nextcloud_service.task_role_arn,
      ]
    }
  }]

  ownership_controls = "BucketOwnerEnforced" # Disable all S3 bucket ACL

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

  tags = var.tags
}
