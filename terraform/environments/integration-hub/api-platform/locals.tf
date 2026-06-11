locals {
  api_configuration    = try(local.application_data.accounts[local.environment].api_configuration, {})
  cors_allowed_origins = try(local.api_configuration.cors_allowed_origins, [])
  transfer_clients     = try(local.application_data.accounts[local.environment].transfer_clients, {})
}
