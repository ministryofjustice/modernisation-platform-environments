output "aws_s3_bucket_arn" {
  description = "Map of bucket names (as specified, without the enviroment prefix) to the ARN of the created buckets."
  value = {
    for k,v in aws_s3_bucket.default:
      trimprefix(k,"${local.environment_name}-") => {
        arn = v.arn
      }
  }
}