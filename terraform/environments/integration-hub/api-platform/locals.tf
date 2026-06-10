locals {
  api_configuration = try(local.application_data.accounts[local.environment].api_configuration, {})
  transfer_clients  = try(local.application_data.accounts[local.environment].transfer_clients, {})
}
