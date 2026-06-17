# ---------------------------------------------------------------------------------------------------------------------
# S3
# ---------------------------------------------------------------------------------------------------------------------
module "flink_artifacts_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"
  
  create_bucket = contains(local.deploy_to, local.environment) ? true : false
  
  bucket = "streaming-poc-flink-jars-${local.environment}"
  
  attach_deny_insecure_transport_policy = true
  
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = contains(local.deploy_to, local.environment) ? aws_kms_key.s3[0].arn : null
        sse_algorithm     = "aws:kms"
      }
    }
  }
  
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
