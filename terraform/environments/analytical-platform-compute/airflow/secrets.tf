module "airflow_connections_slack_api_default_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name        = "airflow/connections/slack_api_default"
  description = "https://api.slack.com/apps/A06NU3WMDSS/"
  kms_key_id  = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = local.tags
}
