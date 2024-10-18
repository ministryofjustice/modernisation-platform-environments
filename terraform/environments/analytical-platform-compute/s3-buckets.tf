module "apc_buckets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.apc_buckets
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "4.2.1"

  bucket                               = each.value.bucket
  force_destroy                        = each.value.force_destroy
  object_lock_enabled                  = try(each.value.object_lock_enabled, null)
  tags                                 = local.tags
  server_side_encryption_configuration = each.value.server_side_encryption_configuration
  attach_policy                        = can(each.value.policy)
  policy                               = try(each.value.policy, null)
  lifecycle_rule                       = try(each.value.lifecycle_rule, [])
  versioning                           = try(each.value.versioning, null)
  attach_public_policy                 = try(each.value.public_access_block, null)
  block_public_acls                    = try(each.value.public_access_block.block_public_acls, true)
  block_public_policy                  = try(each.value.public_access_block.block_public_policy, true)
  ignore_public_acls                   = try(each.value.public_access_block.ignore_public_acls, true)
  restrict_public_buckets              = try(each.value.public_access_block.restrict_public_buckets, true)
  acl                                  = try(each.value.acl, null)
}

moved {
  from = module.mlflow_bucket.aws_s3_bucket.this[0]
  to   = module.apc_buckets["mlflow_bucket"].aws_s3_bucket.this[0]
}

moved {
  from = module.mlflow_bucket.aws_s3_bucket_public_access_block.this[0]
  to   = module.apc_buckets["mlflow_bucket"].aws_s3_bucket_public_access_block.this[0]
}

moved {
  from = module.mlflow_bucket.aws_s3_bucket_server_side_encryption_configuration.this[0]
  to   = module.apc_buckets["mlflow_bucket"].aws_s3_bucket_server_side_encryption_configuration.this[0]
}
