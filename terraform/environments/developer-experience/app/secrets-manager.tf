module "github_app_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/github-app"
  kms_key_id = module.kms_key.key_arn

  secret_string = jsonencode({
    app_id          = "CHANGEME"
    client_id       = "CHANGEME"
    client_secret   = "CHANGEME"
    installation_id = "CHANGEME"
    private_key     = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}

module "entra_app_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/entra-app"
  kms_key_id = module.kms_key.key_arn

  secret_string = jsonencode({
    client_id     = "CHANGEME"
    secret_id     = "CHANGEME"
    client_secret = "CHANGEME"
    tenant_id     = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "2027-03-03" }
  )
}

module "notify_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/notify"
  kms_key_id = module.kms_key.key_arn

  secret_string = jsonencode({
    api_key                            = "CHANGEME"
    project_member_added_template_id   = "CHANGEME"
    project_member_removed_template_id = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}

module "sentry_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/sentry"
  kms_key_id = module.kms_key.key_arn

  secret_string = jsonencode({
    dsn = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}
