module "pagerduty_api_key_secret" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=f3d3da1c801816563080065c5f37f212c8dee444" # v2.2.0

  name                    = local.pagerduty_secret_name
  description             = "PagerDuty API token for Integration Hub Terraform"
  create_secret_version   = false
  recovery_window_in_days = 30

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}
