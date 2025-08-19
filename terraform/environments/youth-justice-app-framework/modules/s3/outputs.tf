output "aws_s3_bucket" {
  description = "Map of s3 buckets created by this module. Key is the input bucket names (as specified, without the enviroment prefix). Currently contains the arn for each s3 bucket."
  value = {
    for k, v in aws_s3_bucket.default :
    trimprefix(k, "${local.environment_name}-") => {
      arn = v.arn
    }
  }
}

output "aws_s3_bucket_id" {
  description = "Map of s3 bucket IDs created by this module. Key is the input bucket names (as specified, without the enviroment prefix). Currently contains the id for each s3 bucket."
  value = {
    for k, v in aws_s3_bucket.default :
    trimprefix(k, "${local.environment_name}-") => {
      id = v.id
    }
  }
}
