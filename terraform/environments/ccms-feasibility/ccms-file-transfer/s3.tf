# Business Central inbound bucket. Files land in <base path>/inbound, trigger the process-file Lambda,
# and are moved to archive/ or error/ by the Financial Transfers API.

module "s3_bc_inbound" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"

  bucket_name        = local.bc_bucket_name
  versioning_enabled = true

  # BC uploads arrive without KMS request headers, so the bucket's default encryption applies
  sse_algorithm  = "aws:kms"
  custom_kms_key = aws_kms_key.fin_transfer.arn

  bucket_policy = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_bc_inbound.bucket.arn,
          "${module.s3_bc_inbound.bucket.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "DenyTLSOlderThan12"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_bc_inbound.bucket.arn,
          "${module.s3_bc_inbound.bucket.arn}/*",
        ]
        Condition = {
          NumericLessThan = { "s3:TlsVersion" = "1.2" }
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
      id      = "delete-files-after-42-days"
      enabled = "Enabled"
      prefix  = ""
      tags    = {}

      expiration = {
        days = 42
      }
    },
    {
      id      = "delete-noncurrent-versions-asap"
      enabled = "Enabled"
      prefix  = ""
      tags    = {}

      noncurrent_version_expiration = {
        days = 1
      }
    },
  ]

  tags = merge(local.tags, {
    Name = local.bc_bucket_name
  })
}

resource "aws_s3_object" "bc_inbound_folders" {
  for_each = toset(local.bc_bucket_folders)

  bucket = module.s3_bc_inbound.bucket.id
  key    = "${each.value}/"
}

resource "aws_s3_bucket_notification" "bc_inbound" {
  bucket = module.s3_bc_inbound.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_file_from_bucket.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${local.bc_bucket_base_path}/inbound/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
