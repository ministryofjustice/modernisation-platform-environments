module "pagerduty_api_key_secret" {
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  name                    = local.pagerduty_secret_name
  description             = "PagerDuty API token for Integration Hub Terraform"
  kms_key_id              = module.pagerduty_api_key_kms[0].key_arn
  create_secret_version   = false
  ignore_secret_changes   = true
  enable_rotation         = false
  recovery_window_in_days = 30

  tags = merge(
    local.tags,
    { "credential-expiration" = "none" }
  )
}
