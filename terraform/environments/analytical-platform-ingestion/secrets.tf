# TODO: look at using https://registry.terraform.io/modules/terraform-aws-modules/secrets-manager/aws/latest
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  name       = "ingestion/govuk-notify/api-key"
  kms_key_id = module.govuk_notify_kms.key_arn
}

resource "aws_secretsmanager_secret" "govuk_notify_templates" {
  name       = "ingestion/govuk-notify/templates"
  kms_key_id = module.govuk_notify_kms.key_arn
}
