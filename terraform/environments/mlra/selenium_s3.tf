resource "aws_s3_bucket" "selenium_report" {
  bucket = "laa-${local.application_name}-deployment-pipeline-pipelinereportbucket"

  tags = merge(
    local.tags,
    {
      Name = "laa-${local.application_name}-deployment-pipeline-pipelinereportbucket"
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "report_sse" {
  bucket = aws_s3_bucket.selenium_report.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "report_lifecycle" {
  bucket = aws_s3_bucket.selenium_report.id

  rule {
    id = "monthly-expiration"
    expiration {
      days = 31
    }
    noncurrent_version_expiration {
      noncurrent_days = 31
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "report_versioning" {
  bucket = aws_s3_bucket.selenium_report.id
  versioning_configuration {
    status = "Enabled"
  }
}
