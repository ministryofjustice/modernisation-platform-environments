module "actions_runners_create_a_derived_table_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "actions-runners/create-a-derived-table"
  description = "moj-data-platform-robot: https://github.com/settings/personal-access-tokens/2208432"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      "expiry-date" = "2024-10-26"
    }
  )
}

module "actions_runners_airflow_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "actions-runners/airflow"
  description = "moj-data-platform-robot: https://github.com/settings/personal-access-tokens/3544241"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      "expiry-date" = "2024-10-26"
    }
  )
}

module "actions_runners_airflow_create_a_pipeline_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "actions-runners/airflow-create-a-pipeline"
  description = "moj-data-platform-robot: https://github.com/settings/personal-access-tokens/3733767"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      "expiry-date" = "2025-07-31"
    }
  )
}

module "ui_sentry_dsn_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "ui/sentry-dsn"
  description = "Sentry DSN for Analytical Platform UI"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}

module "ui_azure_client_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "ui/azure-client"
  description = "Azure client secret for Analytical Platform UI"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}

module "ui_azure_tenant_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "ui/azure-tenant"
  description = "Azure tenant secret for Analytical Platform UI"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}
