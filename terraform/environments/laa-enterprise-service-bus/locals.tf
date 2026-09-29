#### This file can be used to store locals specific to the member account ####
locals {
  application_name_short = "hub20"

  # S3 Buckets for Access Logs
  s3_access_logs_source_arns = [
    aws_s3_bucket.data.arn,
    "arn:aws:s3:::${local.application_name_short}-${local.environment}-lambda-files"
  ]
}