locals {
  s3_access_logs_source_arns = [
    aws_s3_bucket.laa_oem_shared.arn
  ]
}