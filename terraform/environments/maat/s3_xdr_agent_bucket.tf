module "xdr-agent-s3" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-xdr-agent"
  replication_enabled = false
  versioning_enabled  = false
  force_destroy       = false

  lifecycle_rule = [
    {
      id      = "xdr-agent-cleanup"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "xdr"
        autoclean = "true"
      }

      expiration = {
        days = 120
      }

      noncurrent_version_expiration = {
        days = 120
      }
    }
  ]

  tags = local.tags
}
