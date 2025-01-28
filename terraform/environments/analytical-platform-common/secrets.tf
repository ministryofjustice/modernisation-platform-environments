module "analytical_platform_compute_cluster_data_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name       = "analytical-platform-compute/cluster-data"
  kms_key_id = module.secrets_manager_common_kms.key_arn

  secret_string = jsonencode({
    change_me = "CHANGEME"
  })
  ignore_secret_changes = true

  tags = local.tags
}
