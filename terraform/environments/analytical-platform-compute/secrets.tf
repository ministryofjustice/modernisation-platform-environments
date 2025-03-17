module "airflow_connections_slack_api_default_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "airflow/connections/slack_api_default"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}

module "mlflow_auth_rds_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "mlflow/mlflow_auth_rds"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = random_password.mlflow_auth_rds.result
  ignore_secret_changes = false

  tags = local.tags
}

module "mlflow_rds_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "mlflow/mlflow_rds"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = random_password.mlflow_rds.result
  ignore_secret_changes = false

  tags = local.tags
}

module "mlflow_admin_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "mlflow/mlflow_admin"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = random_password.mlflow_admin.result
  ignore_secret_changes = false

  tags = local.tags
}

module "ui_rds_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ui/ui_rds"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = random_password.ui_rds.result
  ignore_secret_changes = false

  tags = local.tags
}

module "ui_app_secrets_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ui/ui_app_secrets"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = module.common_secrets_manager_kms.key_arn

  secret_string         = random_password.ui_app_secrets.result
  ignore_secret_changes = false

  tags = local.tags
}
