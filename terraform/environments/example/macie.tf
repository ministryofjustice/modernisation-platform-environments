# Create macie account

resource "aws_macie2_account" "example" {
  finding_publishing_frequency = "ONE_HOUR"
  status                       = "ENABLED"
}

# Now create a job

resource "aws_macie2_classification_job" "example" {
  job_type = "ONE_TIME"
  name     = "<an appropriate job name>"
  s3_job_definition {
    bucket_definitions {
      account_id = local.environment_management.account_ids[terraform.workspace]
      buckets = [
        data.aws_s3_bucket.bucket1.id,
        data.aws_s3_bucket.bucket2.id,
        data.aws_s3_bucket.bucket3.id,
      ]
    }
  }
  job_status = "RUNNING"
  depends_on = [aws_macie2_account.example]
}