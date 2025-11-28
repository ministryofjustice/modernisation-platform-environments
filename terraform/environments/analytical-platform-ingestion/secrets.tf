# TODO: look at using https://registry.terraform.io/modules/terraform-aws-modules/secrets-manager/aws/latest
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret

  name       = "ingestion/govuk-notify/api-key"
  kms_key_id = module.govuk_notify_kms.key_arn
}

resource "aws_secretsmanager_secret" "govuk_notify_templates" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret

  name       = "ingestion/govuk-notify/templates"
  kms_key_id = module.govuk_notify_kms.key_arn
}

resource "aws_secretsmanager_secret" "slack_token" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret

  name       = "ingestion/slack-token"
  kms_key_id = module.slack_token_kms.key_arn
}

module "datasync_dom1_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name       = "datasync/dom1"
  kms_key_id = module.datasync_credentials_kms.key_arn

  ignore_secret_changes = true
  secret_string = jsonencode({
    username = "CHANGEME"
    password = "CHANGEME"
  })

  tags = local.tags
}

module "datasync_include_paths_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name       = "datasync/include-paths"
  kms_key_id = module.secretsmanager_common_kms.key_arn

  ignore_secret_changes = true
  secret_string         = "CHANGEME"

  tags = local.tags
}

module "datasync_exclude_path_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name       = "datasync/exclude-paths"
  kms_key_id = module.secretsmanager_common_kms.key_arn

  ignore_secret_changes = true
  secret_string         = "CHANGEME"

  tags = local.tags
}

module "laa_data_analysis_bucket_list" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name       = "laa/bucket-list"
  kms_key_id = module.secretsmanager_common_kms.key_arn

  ignore_secret_changes = true
  secret_string         = "CHANGEME"

  tags = local.tags
}

module "laa_data_analysis_keys" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.1"

  name       = "laa/keys"
  kms_key_id = module.secretsmanager_common_kms.key_arn

  ignore_secret_changes = true
  secret_string         = "CHANGEME"

  tags = local.tags
}

# Moved blocks to preserve existing resources
moved {
  from = module.laa_data_analysis_bucket_list
  to   = module.laa_data_analysis_bucket_list[0]
}

moved {
  from = module.laa_data_analysis_keys
  to   = module.laa_data_analysis_keys[0]
}
