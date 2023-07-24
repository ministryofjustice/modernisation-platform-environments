#### This file can be used to store secrets specific to the member account ####

# Nomis Source Secrets
resource "aws_secretsmanager_secret" "nomis" {
  name = "external/${local.project}-nomis-source-secrets"

  tags = merge(
    local.all_tags,
    {
      Name          = "external/${local.project}-nomis-source-secrets"
      Resource_Type = "Secrets"
      Jira          = "DPR-XXXX"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "nomis" {
  secret_id     = aws_secretsmanager_secret.nomis.id
  secret_string = jsonencode(local.nomis_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# Redshift Access Secrets
resource "aws_secretsmanager_secret" "redshift" {
  name = "dpr-redshift-sqlworkbench-${local.env}"

  recovery_window_in_days = 0

  tags = merge(
    local.all_tags,
    {
      Name          = "dpr-redshift-sqlworkbench-${local.env}"
      Resource_Type = "Secrets"
      Jira          = "DPR-XXXX"
      Redshift      = "redshift"
    }
  )
}

#Redshift secrets and placeholders
resource "aws_secretsmanager_secret_version" "redshift" {
  secret_id     = aws_secretsmanager_secret.redshift.id
  secret_string = jsonencode(local.redshift_secrets)
}

# Slack ALerts URL
module "slack_alerts_url" {
  count                   = local.enable_slack_alerts_url ? 1 : 0

  source                  = "./modules/secrets_manager"
  name                    = "${local.project}-slack-alerts-url-${local.environment}"
  description             = "DPR Slack Alerts URL"
  type                    = "MONO"
  secret_value            = "SLACK_ALERTS_URL_PLACEHOLDER"
  ignore_local_changes    = true

  lifecycle_rules = {
    ignore_changes = [secret_string, ]
  }
  
  tags = merge(
    local.all_tags,
    {
      Resource_Group = "monitoring"
      Jira           = "DPR-569"
      Resource_Type  = "Secret"
      Name           = "${local.project}-slack-alerts-url-${local.environment}"      
    }
  )
}