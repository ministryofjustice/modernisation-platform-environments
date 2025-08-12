output "aws_s3_bucket_arn" {
  value = {for k,v in aws_s3_bucket.default:
    trimprefix(k,"${local.environment_name}-") =>
       aws_s3_bucket.default.*.arn
  }
}