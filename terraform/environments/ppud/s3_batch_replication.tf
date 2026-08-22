##########################################################################################
# S3 Batch Replication IAM Role/Policy (DEV only)
##########################################################################################

locals {
  s3_batch_replication_dev_enabled = local.is-development

  s3_batch_replication_dev_destination = "arn:aws:s3:::ppud-bak-replication-development-${local.environment_management.account_ids["digital-prison-reporting-development"]}-eu-west-2-an"
}

resource "aws_iam_role" "s3_batch_replication_dev" {
  count = local.s3_batch_replication_dev_enabled ? 1 : 0

  name = "iam_role_s3_batch_replication_moj_database_source_dev"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "batchoperations.s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_batch_replication_dev" {
  count = local.s3_batch_replication_dev_enabled ? 1 : 0

  name        = "iam_policy_s3_batch_replication_moj_database_source_dev"
  path        = "/"
  description = "IAM policy for S3 Batch Replication from moj-database-source-dev"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SourceBucketConfigurationRead"
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:GetBucketVersioning",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:PutInventoryConfiguration",
          "s3:GetInventoryConfiguration"
        ]
        Resource = [
          aws_s3_bucket.s3_replication["database_source_dev"].arn
        ]
      },
      {
        Sid    = "SourceObjectReadForReplication"
        Effect = "Allow"
        Action = [
          "s3:InitiateReplication",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
        ]
        Resource = [
          "${aws_s3_bucket.s3_replication["database_source_dev"].arn}/*"
        ]
      },
      {
        Sid    = "DestinationObjectReplication"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = [
          local.s3_batch_replication_dev_destination,
          "${local.s3_batch_replication_dev_destination}/*"
        ]
      },
      {
        Sid    = "ManifestAndCompletionReport"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.s3_replication["database_source_dev"].arn,
          "${aws_s3_bucket.s3_replication["database_source_dev"].arn}/batch-replication/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_batch_replication_dev" {
  count = local.s3_batch_replication_dev_enabled ? 1 : 0

  role       = aws_iam_role.s3_batch_replication_dev[0].name
  policy_arn = aws_iam_policy.s3_batch_replication_dev[0].arn
}
