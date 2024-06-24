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

# DPS Source Secrets
# PlaceHolder Secrets
resource "aws_secretsmanager_secret" "dps" {
  for_each = toset(local.dps_domains_list)
  name     = "external/${local.project}-${each.value}-source-secrets"

  tags = merge(
    local.all_tags,
    {
      Name          = "external/${local.project}-${each.value}-source-secrets"
      Resource_Type = "Secrets"
      Source        = "DPS"
      Domain        = each.value
      Jira          = "DPR2-341"
    }
  )
}

resource "aws_secretsmanager_secret_version" "dps" {
  for_each = toset(local.dps_domains_list)

  secret_id     = aws_secretsmanager_secret.dps[each.key].id
  secret_string = jsonencode(local.dps_secrets_placeholder)

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

# BO biprws Secrets
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "biprws" {
  count = local.enable_biprws_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.biprws[0].id
  secret_string = jsonencode(local.biprws_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.biprws]
}

# DPS Source Secrets
# PlaceHolder Secrets
resource "aws_secretsmanager_secret" "biprws" {
  count = local.enable_biprws_secrets ? 1 : 0

  name = "external/busobj-converter/biprws"

  recovery_window_in_days = 0

  tags = merge(
    local.all_tags,
    {
      Name          = "external/busobj-converter/biprws"
      Resource_Type = "Secrets"
      Source        = "NART"
      Jira          = "DPR2-527"
    }
  )
}

# CP k8s Token
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "cp_k8s_secrets" {
  count = local.enable_cp_k8s_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.cp_k8s_secrets[0].id
  secret_string = jsonencode(local.cp_k8s_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.cp_k8s_secrets]
}

# DPS Source Secrets
# PlaceHolder Secrets
resource "aws_secretsmanager_secret" "cp_k8s_secrets" {
  count = local.enable_cp_k8s_secrets ? 1 : 0

  name = "external/cloud_platform/k8s_auth"

  recovery_window_in_days = 0

  tags = merge(
    local.all_tags,
    {
      Name          = "external/cloud_platform/k8s_auth"
      Resource_Type = "Secrets"
      Source        = "CP"
      Jira          = "DPR2-768"
    }
  )
}

# BODMIS CP k8s Token
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "cp_bodmis_k8s_secrets" {
  count = local.enable_cp_bodmis_k8s_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.cp_bodmis_k8s_secrets[0].id
  secret_string = jsonencode(local.cp_bodmis_k8s_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.cp_bodmis_k8s_secrets]
}

# DPS Source Secrets
# PlaceHolder Secrets
resource "aws_secretsmanager_secret" "cp_bodmis_k8s_secrets" {
  count = local.enable_cp_bodmis_k8s_secrets ? 1 : 0

  name = "external/cloud_platform/bodmis_k8s_auth"

  recovery_window_in_days = 0

  tags = merge(
    local.all_tags,
    {
      Name          = "external/cloud_platform/bodmis_k8s_auth"
      Resource_Type = "Secrets"
      Source        = "CP"
      Jira          = "DPR2-908"
    }
  )
}

## DBT Analytics EKS Cluster Identifier
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "dbt_secrets" {
  count = local.enable_dbt_k8s_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.dbt_secrets[0].id
  secret_string = jsonencode(local.dbt_k8s_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.dbt_secrets]
}

resource "aws_secretsmanager_secret" "dbt_secrets" {
  count = local.enable_dbt_k8s_secrets ? 1 : 0

  name = "external/analytics_platform/k8s_dbt_auth"

  recovery_window_in_days = 0

  tags = merge(
    local.all_tags,
    {
      Name          = "external/cloud_platform/k8s_auth"
      Resource_Type = "Secrets"
      Source        = "Analytics-Platform"
      Jira          = "DPR2-751"
    }
  )
}