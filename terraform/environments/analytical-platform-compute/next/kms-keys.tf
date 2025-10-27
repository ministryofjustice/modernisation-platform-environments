module "rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["rds/${local.component_name}"]
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
