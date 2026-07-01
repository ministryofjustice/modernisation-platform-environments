locals {
  serco_fms_key_distribution_bucket_prefix = (
    "${local.bucket_prefix}-serco-fms-keys-"
  )

  serco_fms_key_distribution_files_prefix = "files"

  serco_fms_key_distribution_config_prefix = "config"

  serco_fms_key_distribution_allowlist_key = (
    "${local.serco_fms_key_distribution_config_prefix}/${local.environment_shorthand}/allowlist.json"
  )
}

module "s3-serco-fms-key-distribution-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9f"

  bucket_prefix      = local.serco_fms_key_distribution_bucket_prefix
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "expire-encrypted-key-files"
      enabled = "Enabled"
      prefix  = "${local.serco_fms_key_distribution_files_prefix}/"

      tags = {
        rule      = "serco-fms-key-distribution-files"
        autoclean = "true"
      }

      expiration = {
        days = 14
      }

      noncurrent_version_expiration = {
        days = 14
      }
    }
  ]

  tags = merge(
    local.tags,
    {
      resource-type = "serco-fms-key-distribution"
      purpose       = "serco-fms-key-distribution"
    }
  )
}

resource "aws_s3_object" "serco_fms_key_distribution_allowlist" {
  bucket = module.s3-serco-fms-key-distribution-bucket.bucket.id
  key    = local.serco_fms_key_distribution_allowlist_key

  content_type = "application/json"

  content = jsonencode({
    schema_version = "1.0"
    environment    = local.environment_shorthand
    enabled        = true
    test_mode      = true

    notify_recipients = [
      {
        email        = "Khristiania.Raihan@justice.gov.uk"
        name         = "EM test recipient"
        organisation = "EM Data Hub"
        enabled      = true
      }
    ]

    claim_recipients = [
      {
        email                = "Khristiania.Raihan@justice.gov.uk"
        name                 = "EM test recipient"
        organisation         = "EM Data Hub"
        enabled              = true
        can_claim_file       = true
        can_request_password = true
      }
    ]
  })

  server_side_encryption = "AES256"

  tags = merge(
    local.tags,
    {
      purpose = "serco-fms-key-distribution-allowlist"
    }
  )
}