module "cur_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/cur"]
  description           = "S3 CUR KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "cur_v2_hourly" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "coat-${local.environment}-cur-v2-hourly"

  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.cur_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}