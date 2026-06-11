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
  description = "Allows DataSync to read from source and write to destination buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::your-source-bucket-name",      # REPLACE WITH YOUR SOURCE BUCKET
          "arn:aws:s3:::your-destination-bucket-name"  # REPLACE WITH YOUR DESTINATION BUCKET
        ]
      },
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::your-source-bucket-name/*",      # REPLACE WITH YOUR SOURCE BUCKET
          "arn:aws:s3:::your-destination-bucket-name/*"  # REPLACE WITH YOUR DESTINATION BUCKET
        ]
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
  # REPLACE WITH YOUR SOURCE BUCKET
  s3_bucket_arn = "arn:aws:s3:::your-source-bucket-name" 
  
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_location_s3" "destination" {
  # REPLACE WITH YOUR DESTINATION BUCKET
  s3_bucket_arn = "arn:aws:s3:::your-destination-bucket-name" 
  
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

# -----------------------------------------------------------------------------
# DataSync Task (Runs on the 20th of every month)
# -----------------------------------------------------------------------------
resource "aws_datasync_task" "historic_replication" {
  name                     = "historic-data-monthly-sync"
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn

  # CloudWatch Log Group for DataSync execution logs (Optional but highly recommended)
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs.arn

  # cron(0 0 20 * ? *) runs at midnight UTC on the 20th of every month
  schedule {
    schedule_expression = "cron(0 0 20 * ? *)"
  }

  options {
    # REMOVE ensures GDPR deletions in the source are mirrored to the destination
    preserve_deleted_files = "REMOVE" 
    
    # CHANGED ensures it only scans and syncs modifications, not the entire TBs of data
    transfer_mode = "CHANGED"

    # Keeps standard metadata intact
    posix_permissions = "NONE"
    uid               = "NONE"
    gid               = "NONE"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Logs for Monitoring the Task
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "datasync_logs" {
  name              = "/aws/datasync/historic-data-monthly-sync"
  retention_in_days = 14
}

# Allow DataSync to write to the CloudWatch log group
resource "aws_cloudwatch_log_resource_policy" "datasync_logs_policy" {
  policy_name     = "datasync-logs-policy"
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