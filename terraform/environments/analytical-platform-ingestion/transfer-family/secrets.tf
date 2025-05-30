module "govuk_notify_templates" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name       = "transfer/govuk-notify/templates"
  kms_key_id = module.transfer_govuk_notify_kms.key_arn

  ignore_secret_changes = true
  secret_string = jsonencode({
    transfer_service_unsupported      = "20454a21-2a96-4416-8615-7a8139515515"
    transfer_service_access_denied    = "9bd98068-2765-4b12-8fbb-bc2b44e0ccc2"
    transfer_service_failure          = "403e269a-6f81-468c-851c-9e9bf98f2a8f"
    transfer_service_file_transferred = "854b00a1-edf9-4a0f-9156-09845e4a5523"
    transfer_service_threats_found    = "64d647d9-61ce-4a53-93ef-ed40452a9878"
  })

  tags = local.tags
}

module "govuk_notify_api_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name       = "transfer/govuk-notify/api-key"
  kms_key_id = module.transfer_govuk_notify_kms.key_arn

  ignore_secret_changes = true
  secret_string         = "CHANGEME"

  tags = local.tags
}
