
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
      "aws-sam-cli-managed-default-samclisourcebucket-1leowh6voenwy",
      "config-20220407082146408700000002",
      "macie-test-results-cooker"
      ]
    }
  }
}