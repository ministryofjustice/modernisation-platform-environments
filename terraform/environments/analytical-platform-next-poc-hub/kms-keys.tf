module "s3_mojap_next_poc_athena_query_kms_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/${local.athena_query_bucket_name}"]
  enable_default_policy = true

  deletion_window_in_days = 7
}
