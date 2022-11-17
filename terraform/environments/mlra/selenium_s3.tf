resource "aws_s3_bucket" "selenium_report" {
  count  = local.environment == "development" ? 1 : 0
  bucket = "laa-${local.application_name}-deployment-pipeline-pipelinereportbucket"

  tags = merge(
    local.tags,
    {
      Name = "laa-${local.application_name}-deployment-pipeline-pipelinereportbucket"
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "report_sse" {
  count = local.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.selenium_report[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "report_lifecycle" {
  count = local.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.selenium_report[count.index].id

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
  count = local.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.selenium_report[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}
