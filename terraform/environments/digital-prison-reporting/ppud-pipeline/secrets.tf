# Secret to restore database
# https://github.com/awsdocs/aws-cloudformation-user-guide/blob/c03a45977c5a506e09a22dbe05ff980bec79b805/doc_source/aws-properties-rds-database-instance.md#cfn-rds-dbinstance-masteruserpassword
module "ppud_rds_export_secret" {
  count = local.is-test ? 0 : 1

  # v2.1.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea"

  name       = "ppud-rds-export-password"
  kms_key_id = module.ppud_kms[0].key_arn

  ignore_secret_changes            = true
  create_random_password           = true
  random_password_length           = 13
  random_password_override_special = "!#$&*?"

  tags = merge(
    local.tags,
    {
      resource-type = "Secrets Manager"
    }
  )

}

# Secret for slack webhook for notifications/alerts
# Note: This is initialized with a placeholder value and must be updated
# in AWS Secrets Manager after deployment with the actual webhook URL.
module "ppud_slack_webhook" {
  count = local.is-test ? 0 : 1

  # v2.1.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea"

  name       = "ppud-notifications-slack-webhook"
  kms_key_id = module.ppud_kms[0].key_arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      resource-type = "Secrets Manager"
    }
  )

}
