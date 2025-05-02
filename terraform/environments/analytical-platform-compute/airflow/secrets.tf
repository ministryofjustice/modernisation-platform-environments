module "actions_runners_airflow_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

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
  version = "1.3.1"

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

module "airflow_connections_slack_api_default_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "airflow/connections/slack_api_default"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}
