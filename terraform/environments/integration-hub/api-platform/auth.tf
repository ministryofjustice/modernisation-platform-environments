module "api_user_credentials_secret" {
  for_each = local.auth_users

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-user-${each.key}"
  description             = "HTTPS upload credentials for ${each.key}"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  # This value is a placeholder. Populate the real password directly in AWS
  # Secrets Manager and Terraform will ignore later secret value changes.
  secret_string = jsonencode({
    username = each.key
    password = "replace-me"
    roleName = each.value.role_name
  })

  tags = local.tags
}

module "api_system_bearer_token_secret" {
  for_each = local.auth_system_principals

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-system-${each.key}"
  description             = "Bearer token secret for ${each.key}"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  # This value is a placeholder. Populate the real token directly in AWS
  # Secrets Manager and Terraform will ignore later secret value changes.
  secret_string = jsonencode({
    tokenId     = each.key
    bearerToken = "replace-me"
    roleName    = each.value.role_name
  })

  tags = local.tags
}

module "api_docs_basic_auth_secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.application_name}-${local.component_name}-${local.environment}-docs-basic-auth"
  description             = "Basic auth credentials for the protected Swagger UI"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  # This value is a placeholder. Populate the real password directly in AWS
  # Secrets Manager and Terraform will ignore later secret value changes.
  secret_string = jsonencode({
    username = local.api_docs_configuration.basic_auth_username
    password = "replace-me"
  })

  tags = local.tags
}
