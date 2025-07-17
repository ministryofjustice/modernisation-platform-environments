module "dashboard_service_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["rds/dashboard-service"]
  description           = "Dashboard Service RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
