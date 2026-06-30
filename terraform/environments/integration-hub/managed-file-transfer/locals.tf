locals {
  build_mft                = try(local.application_data.accounts[local.environment].build_mft, false)
  bucket_configuration     = try(local.application_data.accounts[local.environment].bucket_configuration, {})
  custom_idp_configuration = try(local.application_data.accounts[local.environment].custom_idp_configuration, {})
  iam_configuration        = try(local.application_data.accounts[local.environment].iam_configuration, {})
  web_app_hostname         = local.is-production == false ? "web.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "web.managed-file-transfer.service.justice.gov.uk"
  web_app_origin           = "https://${local.web_app_hostname}"
  notification_configuration = try(
    local.application_data.accounts[local.environment].notification_configuration,
    {},
  )
  vpc_configuration = try(local.application_data.accounts[local.environment].vpc_configuration, {})
}
