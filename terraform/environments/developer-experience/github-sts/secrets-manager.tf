module "github_app_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name       = "${local.component_name}/github-app"
  kms_key_id = module.kms_key.key_arn

  secret_string = jsonencode({
    app_id          = "CHANGEME"
    client_id       = "CHANGEME"
    installation_id = "CHANGEME"
    private_key     = "CHANGEME"
  })

  ignore_secret_changes = true

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}
