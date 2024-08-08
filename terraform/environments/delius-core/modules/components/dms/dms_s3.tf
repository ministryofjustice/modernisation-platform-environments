module "s3_bucket_dms_destination" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

  bucket_prefix      = "${local.dms_s3_local_bucket_prefix}"
  versioning_enabled = true

  providers = {
    aws.bucket-replication = aws
  }

  bucket_policy_v2 = [
        for dms_s3_writer_role_arn in values(local.dms_s3_bucket_info.dms_s3_writer_role_cross_account_arns) : {
          effect     = "Allow"
          Principals = {
            AWS = dms_s3_writer_role_arn
          }
          actions    = [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ]
        }
  ]

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