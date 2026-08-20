locals {
  build_mft                = try(local.application_data.accounts[local.environment].build_mft, false)
  bucket_configuration     = try(local.application_data.accounts[local.environment].bucket_configuration, {})
  custom_idp_configuration = try(local.application_data.accounts[local.environment].custom_idp_configuration, {})
  iam_configuration        = try(local.application_data.accounts[local.environment].iam_configuration, {})
  web_app_hostname         = local.is-production == false ? "web.${local.environment}.managed-file-transfer.service.justice.gov.uk" : "web.managed-file-transfer.service.justice.gov.uk"
  web_app_origin           = "https://${local.web_app_hostname}"
  client_destination_delivery = try(
    local.application_data.accounts[local.environment].client_destination_delivery,
    {},
  )
  client_destination_delivery_effective = local.environment == "development" ? merge(
    local.client_destination_delivery,
    {
      "products-poc" = merge(
        try(local.client_destination_delivery["products-poc"], {}),
        {
          enabled                 = true
          request_method          = "POST"
          request_timeout_seconds = 900
          request_url             = aws_lambda_function_url.products_poc_destination_presign_api[0].function_url
        }
      )
    }
  ) : local.client_destination_delivery
  notification_configuration = try(
    local.application_data.accounts[local.environment].notification_configuration,
    {},
  )
  vpc_configuration = try(local.application_data.accounts[local.environment].vpc_configuration, {})
}
