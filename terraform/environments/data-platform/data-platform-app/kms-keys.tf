module "data_platform_app_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "data-platform-test" ? 0 : 1

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases               = ["rds/data-platform-app"]
  description           = "Data Platform App RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
