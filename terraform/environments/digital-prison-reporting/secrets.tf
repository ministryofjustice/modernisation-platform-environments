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

# Slack Alerts URL
module "slack_alerts_url" {
  count = local.enable_slack_alerts ? 1 : 0

  source               = "./modules/secrets_manager"
  name                 = "${local.project}-slack-alerts-url-${local.environment}"
  description          = "DPR Slack Alerts URL"
  type                 = "MONO"
  secret_value         = "PLACEHOLDER@EMAIL.COM"
  ignore_secret_string = true

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

# PagerDuty Integration Key
module "pagerduty_integration_key" {
  count = local.enable_pagerduty_alerts ? 1 : 0

  source               = "./modules/secrets_manager"
  name                 = "${local.project}-pagerduty-integration-key-${local.environment}"
  description          = "DPR PagerDuty Integration Key"
  type                 = "MONO"
  secret_value         = "PLACEHOLDER@EMAIL.COM"
  ignore_secret_string = true

  tags = merge(
    local.all_tags,
    {
      Resource_Group = "monitoring"
      Jira           = "DPR-569"
      Resource_Type  = "Secret"
      Name           = "${local.project}-pagerduty-integration-key-${local.environment}"
    }
  )
}

# SonaType Secrets
module "sonatype_registry_secrets" {
  count = local.setup_sonatype_secrets ? 1 : 0

  source               = "./modules/secrets_manager"
  name                 = "${local.project}-sonatype-registry-${local.environment}"
  description          = "SonaType Registry Secrets"
  type                 = "KEY_VALUE"
  secrets              = local.sonatype_secrets_placeholder
  ignore_secret_string = true

  tags = merge(
    local.all_tags,
    {
      Resource_Group = "monitoring"
      Jira           = "DPR2-69"
      Resource_Type  = "Secret"
      Name           = "${local.project}-sonatype-registry-${local.environment}"
    }
  )
}