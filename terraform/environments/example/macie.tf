# Create macie account
# When logging in as adminisitrator this is not needed but may be for our customers
# Account name is MacieAccount. Publishes data every hour (choice are FIFTEEN_MINUTES, ONE_HOUR or SIX_HOURS)
resource "aws_macie2_account" "MacieAccount" {
  finding_publishing_frequency = "ONE_HOUR"
  status                       = "ENABLED"
}

# Now create a job
# Job type options are ONE-TIME and SCHEDULED. If scheduled is chosen you need to select a frequency using schedule_frequency of daily_schedule, weekly_schedule or monthly_schedule
# The buckets should be replaced but a list of buckets to examine. This could be limited to those in the account you are connected to or others to which you have access. 
# Below there is a limited list of those from example shown. 
# There are many other job options available and these should be looked at in terrform [job creation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/macie2_classification_job)

resource "aws_macie2_classification_job" "test" {
  job_type = "ONE_TIME"
  name     = "JOBNAME"
  s3_job_definition {
    bucket_definitions {
      account_id = "MacieAccount"
      buckets    = [
      "bastion-example-example-development-cqx7gf",
      "config-20220505080423816000000003",
      "s3-bucket-example20231124172322406400000006"
      ]
    }
  }
  depends_on = [aws_macie2_account.MacieAccount]
}