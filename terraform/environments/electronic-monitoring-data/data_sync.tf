# -----------------------------------------------------------------------------
# IAM Role for DataSync to access both S3 buckets
# -----------------------------------------------------------------------------
resource "aws_iam_role" "datasync_s3_role" {
  name = "datasync-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "datasync_s3_policy" {
  name        = "datasync-s3-replication-policy"
  description = "Datasync cross bucket policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucketVersions"
        ]
        Effect = "Allow"
        Resource = [
          module.s3-create-a-derived-table-bucket.bucket.arn,
          module.s3-create-a-derived-table-back-up-bucket-staging.bucket.arn
        ]
      },
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${module.s3-create-a-derived-table-bucket.bucket.arn}/staging/*",
          "${module.s3-create-a-derived-table-back-up-bucket-staging.bucket.arn}/staging/*"
        ]
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datasync_s3_attach" {
  role       = aws_iam_role.datasync_s3_role.name
  policy_arn = aws_iam_policy.datasync_s3_policy.arn
}

# -----------------------------------------------------------------------------
# DataSync S3 Locations
# -----------------------------------------------------------------------------
resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = module.s3-create-a-derived-table-bucket.bucket.arn
  subdirectory  = "/staging/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.datasync_s3_attach,
    module.s3-create-a-derived-table-bucket
  ]
}

resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = module.s3-create-a-derived-table-back-up-bucket-staging.bucket.arn
  subdirectory  = "/staging/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.datasync_s3_attach,
    module.s3-create-a-derived-table-back-up-bucket-staging
  ]
}

# -----------------------------------------------------------------------------
# DataSync Task (Runs on the 20th of every month)
# -----------------------------------------------------------------------------
resource "aws_datasync_task" "historic_replication" {
  name                     = "historic-data-monthly-sync"
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs.arn

  # cron(0 0 20 * ? *) runs at midnight UTC on the 20th of every month
  schedule {
    schedule_expression = "cron(0 0 20 * ? *)"
  }

  options {
    # REMOVE ensures GDPR deletions in the source are mirrored to the destination
    preserve_deleted_files = "REMOVE"

    # CHANGED ensures it only scans and syncs modifications
    transfer_mode = "CHANGED"

    verify_mode = "ONLY_FILES_TRANSFERRED"
    log_level   = "TRANSFER"

    posix_permissions = "NONE"
    uid               = "NONE"
    gid               = "NONE"
  }
}

resource "aws_cloudwatch_log_group" "datasync_logs" {
  name              = "/aws/datasync/historic-data-monthly-sync"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_resource_policy" "datasync_logs_policy" {
  policy_name = "datasync-logs-policy"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.datasync_logs.arn}:*"
      }
    ]
  })
}