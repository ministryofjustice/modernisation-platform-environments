module "api_user_credentials_secret" {
  for_each = local.create_service ? local.auth_users : {}

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-user-${each.key}"
  description             = "Benefit checker API Basic authentication credentials for ${each.key}"
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

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-system-${each.key}"
  description             = "Benefit checker API bearer token for ${each.key}"
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
