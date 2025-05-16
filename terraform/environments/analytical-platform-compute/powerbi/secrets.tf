
# Auth0 credentials secret
module "auth0_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "auth0-provider-${local.environment}"
  description = "Auth0 provider credentials"
  kms_key_id  = module.auth0_secrets_kms.key_arn

  # Auth0 credentials stored as JSON
  secret_string = jsonencode({
    domain        = "CHANGEME", # Auth0 domain e.g. your-tenant.auth0.com
    client_id     = "CHANGEME", # Auth0 client ID
    client_secret = "CHANGEME", # Auth0 client secret
    client_metadata = {
      environment = local.environment
      application = "modernisation-platform"
    },
    connection_id = "CHANGEME" # Optional: Auth0 connection ID if needed
  })

  # Ignore changes to secret value to prevent accidental overwrite
  ignore_secret_changes = true

  # Add relevant tags
  tags = merge(
    local.tags,
    local.environment_configuration.powerbi_gateway.tags,
    {
      component = "powerbi"
    }
  )
}

