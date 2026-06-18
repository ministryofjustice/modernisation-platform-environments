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

  tags = local.extended_tags
}

# module "vpc_endpoints" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = "~> 6.0"
#
#   create = contains(local.deploy_to, local.environment) ? true : false
#
#   vpc_id = data.aws_vpc.shared.id
#
#   endpoints = {
#     s3 = {
#       service         = "s3"
#       service_type    = "Gateway"
#       route_table_ids = [data.aws_vpc.shared.main_route_table_id]
#       tags = merge(local.extended_tags, {
#         Name = "s3-endpoint"
#       })
#     }
#   }
# }

