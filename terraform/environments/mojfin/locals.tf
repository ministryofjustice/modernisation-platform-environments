locals {
  # S3 Buckets for Access Logs
  s3_access_logs_source_arns = compact([
    module.s3-bucket-shared.bucket.arn,
    aws_s3_bucket.mojfin_rds_oracle.arn
  ])
}