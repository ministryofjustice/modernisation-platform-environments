# TODO: look at using https://registry.terraform.io/modules/terraform-aws-modules/secrets-manager/aws/latest
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret

  name       = "transfer/govuk-notify/api-key"
  kms_key_id = module.transfer_govuk_notify_kms.key_arn
}

resource "aws_secretsmanager_secret" "govuk_notify_templates" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret

  name       = "transfer/govuk-notify/templates"
  kms_key_id = module.transfer_govuk_notify_kms.key_arn
}
