locals {
  api_configuration      = try(local.application_data.accounts[local.environment].api_configuration, {})
  auth_configuration     = try(local.application_data.accounts[local.environment].auth_configuration, {})
  auth_roles             = try(local.auth_configuration.roles, {})
  auth_users             = try(local.auth_configuration.users, {})
  auth_system_principals = try(local.auth_configuration.system_principals, {})
  cors_allowed_origins   = try(local.api_configuration.cors_allowed_origins, [])
  create_service         = local.is-development
  bootstrap_code_root    = "${path.module}/bootstrap-lambdas"
}
