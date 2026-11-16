locals {
  entra_configuration            = try(local.application_data.accounts[local.environment].entra, {})
  entra_tenant_id                = try(local.entra_configuration.tenant_id, "")
  entra_api_audience             = try(local.entra_configuration.api_audience, "")
  entra_allowed_client_ids       = try(local.entra_configuration.allowed_client_ids, [])
  api_configuration              = try(local.application_data.accounts[local.environment].api_configuration, {})
  auth_configuration             = try(local.application_data.accounts[local.environment].auth_configuration, {})
  auth_roles                     = try(local.auth_configuration.roles, {})
  auth_users                     = try(local.auth_configuration.users, {})
  auth_system_principals         = try(local.auth_configuration.system_principals, {})
  cors_allowed_origins           = try(local.api_configuration.cors_allowed_origins, [])
  downstream_benefit_checker_url = try(local.api_configuration.downstream_benefit_checker_url, "")
  rate_limit                     = try(local.api_configuration.rate_limit, 20)
  burst_limit                    = try(local.api_configuration.burst_limit, 10)
  create_service                 = local.is-development
  bootstrap_code_root            = "${path.module}/bootstrap-lambdas"
}
