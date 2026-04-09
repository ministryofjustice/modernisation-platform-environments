# ---------------------------------------------
# S3 Bucket - Logging
# ---------------------------------------------
module "s3-bucket-sftp-client1" {
  source             = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_name        = local.sftp_client1_bucket_name
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
          module.s3-bucket-sftp-client1.bucket.arn,
          "${module.s3-bucket-sftp-client1.bucket.arn}/*"
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
          module.s3-bucket-sftp-client1.bucket.arn,
          "${module.s3-bucket-sftp-client1.bucket.arn}/*"
        ]
      }
    ]
  })]

  log_bucket    = local.logging_bucket_name
  log_prefix    = "s3access/${local.sftp_client1_bucket_name}"
  sse_algorithm = "AES256"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "delete-noncurrent-versions-after-5-days"
      enabled = "Enabled"

      # No filter → applies to whole bucket
      filter = {}

      noncurrent_version_expiration = {
        days = 7
      }

    },
    {
      id      = "delete-archive-folder-file-after-5-days"
      enabled = "Enabled"

      filter = {
        prefix = "archive/"
      }

      expiration = {
        days = 7 # delete objects 5 days after creation
      }
    }

  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-barclaycard-inbound-mp", local.application_name, local.environment)) }
  )
}


resource "aws_s3_bucket_notification" "sftp_client1_bucket_notification" {
  bucket      = module.s3-bucket-sftp-client1.bucket.id
  eventbridge = true
  topic {
    topic_arn     = data.aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }

  depends_on = [ module.s3-bucket-sftp-client1 ]
}

resource "aws_s3_object" "sftp_client1_folder" {
  bucket = module.s3-bucket-sftp-client1.bucket.id
  for_each = {
    for name in local.sftp_client1_folder_name :
    name => "${name}/"
  }

  key = each.value
}
