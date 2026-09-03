module "s3_inbound" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v11.1.1"

  bucket_name        = "${local.application_name}-inbound"
  versioning_enabled = true

  bucket_policy = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_inbound.bucket.arn,
          "${module.s3_inbound.bucket.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })]

  replication_enabled = false
  replication_region  = "eu-west-2"

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "delete-RBS-BACKUP-folder-file-after-5-days"
      enabled = "Enabled"
      prefix  = "CCMS_PRD_RBS/Inbound/BACKUP/"
      tags    = {}

      expiration = {
        days = 5
      }

      abort_incomplete_multipart_upload_days = 6
    },
    {
      id      = "delete-archive-folder-file-after-5-days"
      enabled = "Enabled"
      prefix  = "archive/"
      tags    = {}

      expiration = {
        days = 5
      }

      abort_incomplete_multipart_upload_days = 6
    },
    {
      id      = "delete-noncurrent-versions-after-5-days"
      enabled = "Enabled"
      prefix  = ""
      tags    = {}

      noncurrent_version_expiration = {
        days = 5
      }

      abort_incomplete_multipart_upload_days = 6
    },
  ]

  tags = merge(local.tags, {
    Name = "${local.application_name}-inbound"
  })
}

module "s3_outbound" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = "${local.application_name}-outbound"
  versioning_enabled = true

  bucket_policy = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_outbound.bucket.arn,
          "${module.s3_outbound.bucket.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })]

  replication_enabled = false
  replication_region  = "eu-west-2"

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "delete-noncurrent-versions-after-5-days"
      enabled = "Enabled"
      prefix  = ""
      tags    = {}

      noncurrent_version_expiration = {
        days = 5
      }

      abort_incomplete_multipart_upload_days = 6
    },
  ]

  tags = merge(local.tags, {
    Name = "${local.application_name}-outbound"
  })
}

module "s3_ftp_lambda" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = "${local.application_name}-ftp-lambda"
  versioning_enabled = true

  bucket_policy = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_ftp_lambda.bucket.arn,
          "${module.s3_ftp_lambda.bucket.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })]

  replication_enabled = false
  replication_region  = "eu-west-2"

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "delete-noncurrent-versions-after-5-days"
      enabled = "Enabled"
      prefix  = ""
      tags    = {}

      noncurrent_version_expiration = {
        days = 5
      }

      abort_incomplete_multipart_upload_days = 6
    },
  ]

  tags = merge(local.tags, {
    Name = "${local.application_name}-ftp-lambda"
  })
}
