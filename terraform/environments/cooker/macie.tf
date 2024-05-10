
# Create macie account

resource "aws_macie2_account" "macieaccess" { 
   finding_publishing_frequency = "ONE_HOUR"
   status                       = "ENABLED"
 }

# Now create a job

resource "aws_macie2_classification_job" "test" {
  job_type = "ONE_TIME"
  name     = "JOBNAME"
  s3_job_definition {
    bucket_definitions {
      account_id = "default_migration_source_account_id"
      buckets    = [
      data.aws_s3_bucket.bucket1.id,
      data.aws_s3_bucket.bucket2.id,
      data.aws_s3_bucket.bucket3.id,
      ]
    }
  }
}