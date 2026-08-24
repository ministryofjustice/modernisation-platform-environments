module "api_user_credentials_secret" {
  for_each = local.create_service ? local.auth_users : {}

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-user-${each.key}"
  description             = "API platform Basic authentication credentials for ${each.key}"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true
  secret_string = jsonencode({
    username = each.key
    password = "replace-me"
    roleName = each.value.role_name
  })
  tags = local.tags
}

module "api_system_bearer_token_secret" {
  for_each = local.create_service ? local.auth_system_principals : {}

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-system-${each.key}"
  description             = "API platform bearer token for ${each.key}"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true
  secret_string = jsonencode({
    tokenId     = each.key
    bearerToken = "replace-me"
    roleName    = each.value.role_name
  })
  tags = local.tags
}
