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
  version = "1.3.1"

  name        = "datasync/dom1"
  kms_key_id  = module.datasync_credentials_kms.key_arn

  ignore_secret_changes = true
  secret_json           = jsonencode({
    username = "CHANGEME"
    password = "CHANGEME"
  })

  tags = local.tags
}
