locals {
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
