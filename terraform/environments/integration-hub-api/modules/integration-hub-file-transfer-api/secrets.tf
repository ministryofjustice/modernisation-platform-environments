module "api_user_credentials_secret" {
  for_each = local.auth_users

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.resource_name_prefix}-${var.environment}-user-${each.key}"
  description             = "HTTPS upload credentials for ${each.key}"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  # Live credentials are populated directly in Secrets Manager after creation.
  secret_string = jsonencode({
    username = each.key
    password = "replace-me"
    roleName = each.value.role_name
  })

  tags = var.tags
}

module "api_system_bearer_token_secret" {
  for_each = local.auth_system_principals

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.resource_name_prefix}-${var.environment}-system-${each.key}"
  description             = "Bearer token secret for ${each.key}"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  # Live credentials are populated directly in Secrets Manager after creation.
  secret_string = jsonencode({
    tokenId     = each.key
    bearerToken = "replace-me"
    roleName    = each.value.role_name
  })

  tags = var.tags
}

module "api_docs_basic_auth_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.resource_name_prefix}-${var.environment}-docs-basic-auth"
  description             = "Basic auth credentials for the protected Swagger UI"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  # Live credentials are populated directly in Secrets Manager after creation.
  secret_string = jsonencode({
    username = local.api_docs_configuration.basic_auth_username
    password = "replace-me"
  })

  tags = var.tags
}