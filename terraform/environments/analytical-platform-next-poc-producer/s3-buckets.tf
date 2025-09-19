module "mojap_next_poc_athena_query_s3_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.7.0"

  bucket = local.athena_query_bucket_name

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_mojap_next_poc_athena_query_kms_key.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "mojap_next_poc_data_s3_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.7.0"

  bucket = local.datastore_bucket_name

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_mojap_next_poc_data_kms_key.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
