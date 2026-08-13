# Secret to restore database
module "ppud_rds_export_secret" {

  # v2.1.0
  source = "github.com/terraform-aws-modules/terraform-aws-secrets-manager?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea"

  name       = "ppud_rds_export_password"
  kms_key_id = module.ppud_kms.key_arn

  ignore_secret_changes   = true
  create_random_password = true
  random_password_length = 13

  tags = merge(
    local.tags,
    {
      resource_type = "Secrets Manager"
    }
  )

}

# Secret for slack webhook for notifications/alerts
module "ppud_slack_webhook" {

  # v2.1.0
  source = "github.com/terraform-aws-modules/terraform-aws-secrets-manager?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea"

  name = "ppud_notifications_slack_webhook"

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      resource_type = "Secrets Manager"
    }
  )

}