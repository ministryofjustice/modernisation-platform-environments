# ---------------------------------------------
# S3 Bucket - bc
# ---------------------------------------------

module "s3-bucket-sftp-bc" {
  source             = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_name        = local.sftp_bc_bucket_name
  versioning_enabled = true
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.s3-bucket-sftp-bc.bucket.arn,
          "${module.s3-bucket-sftp-bc.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "AllowAnalyticalPlatformIngestionService",
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-ingestion-development"]}:role/transfer",
            "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-ingestion-production"]}:role/transfer"
          ]
        },
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging"
        ],
        Resource = [
          module.s3-bucket-sftp-bc.bucket.arn,
          "${module.s3-bucket-sftp-bc.bucket.arn}/*"
        ]
      },
      {
        "Sid" = "RestrictToTLSRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.s3-bucket-sftp-bc.bucket.arn,
          "${module.s3-bucket-sftp-bc.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          },
          "NumericLessThan" : {
            "aws:TLSVersion" : "1.2"
          }
        },
        "Principal" : "*"
      }
    ]
  })]

  log_bucket     = local.logging_bucket_name
  log_prefix     = "s3access/${local.sftp_bc_bucket_name}"
  custom_kms_key = aws_kms_key.s3_sftp_kms_key.arn
  sse_algorithm  = "aws:kms"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "delete-files-after-42-days"
      enabled = "Enabled"
      prefix  = ""

      expiration = {
        days = 42
      }
    },
    {
      id      = "delete-noncurrent-versions-asap"
      enabled = "Enabled"
      prefix  = ""

      noncurrent_version_expiration = {
        days = 1
      }
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-bc-inbound-mp", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "sftp_bucket_notification" {
  bucket      = module.s3-bucket-sftp-bc.bucket.id
  eventbridge = true

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_file_from_bucket_lambda_function.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_prefix       = "ccms-transfer-bc-${local.environment}/inbound/"
  }

  depends_on = [module.s3-bucket-sftp-bc]
}

resource "aws_cloudwatch_event_rule" "sftp_bucket_event_rule" {
  name        = "sftp-bc-bucket-event-rule"
  description = "Event rule to trigger on S3 Object Created events for the sftp-bc bucket"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = ["${module.s3-bucket-sftp-bc.bucket.id}"]
      }
    }
  })
  tags = merge(local.tags, { name = "sftp-bc-bucket-event-rule" })
}

resource "aws_cloudwatch_event_target" "sftp_bucket_event_target" {
  rule      = aws_cloudwatch_event_rule.sftp_bucket_event_rule.name
  target_id = "s3-event-target"
  arn       = data.aws_sns_topic.s3_topic.arn
}

resource "aws_s3_object" "sftp_folder" {
  bucket = module.s3-bucket-sftp-bc.bucket.id
  for_each = {
    for name in local.sftp_bc_folder_name :
    name => "${name}/"
  }

  key = each.value
}
