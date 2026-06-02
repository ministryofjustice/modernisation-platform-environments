module "mojap_compute_athena_s3_kms_eu_west_2" {

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["s3/mojap-compute-athena-query-results-eu-west-2"]
  description           = "Mojap Athena query bucket S3 KMS key for eu-west-2"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
