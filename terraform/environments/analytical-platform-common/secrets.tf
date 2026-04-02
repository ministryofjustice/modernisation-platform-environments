module "analytical_platform_compute_cluster_data_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name       = "analytical-platform-compute/cluster-data"
  kms_key_id = module.secrets_manager_common_kms.key_arn

  secret_string = jsonencode({
    change_me = "CHANGEME"
  })
  ignore_secret_changes = true

  tags = local.tags
}

module "airflow_github_app_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name        = "github/airflow-github-app"
  description = "https://github.com/ministryofjustice/analytical-platform-airflow"

  secret_string = jsonencode({
    app_id          = "CHANGEME"
    client_id       = "CHANGEME"
    installation_id = "CHANGEME"
    private_key     = "CHANGEME"
  })
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}

module "snyk_analytical_platform_airflow_container_scanning_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name        = "snyk/analytical-platform-airflow-container-scanning"
  description = "https://app.snyk.io/org/hq-bf2/manage/service-accounts/b868b874-13e8-423a-88ae-90e63f1df318"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}
