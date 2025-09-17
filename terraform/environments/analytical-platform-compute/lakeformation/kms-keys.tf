module "mojap_compute_athena_s3_kms_eu_west_2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/mojap-compute-athena-query-results-eu-west-2"]
  description           = "Mojap Athena query bucket S3 KMS key for eu-west-2"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
