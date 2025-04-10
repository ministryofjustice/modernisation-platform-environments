#### This file can be used to store secrets specific to the member account ####

# Nomis Source Secrets
resource "aws_secretsmanager_secret" "nomis" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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
# Nomis Test Source Secrets (for Unit Test)
resource "aws_secretsmanager_secret" "nomis-test" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "external/${local.project}-nomis-testing-source-secrets"

  tags = merge(
    local.all_tags,
    {
      Name          = "external/${local.project}-nomis-testing-source-secrets"
      Resource_Type = "Secrets"
      Jira          = "DPR2-1159"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "nomis-test" {
  secret_id     = aws_secretsmanager_secret.nomis-test.id
  secret_string = jsonencode(local.nomis_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# Nomis Source Secrets
resource "aws_secretsmanager_secret" "bodmis" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "external/${local.project}-bodmis-source-secret"

  tags = merge(
    local.all_tags,
    {
      Name          = "external/${local.project}-bodmis-source-secret"
      Resource_Type = "Secrets"
      Jira          = "DPR2-721"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "bodmis" {
  secret_id     = aws_secretsmanager_secret.bodmis.id
  secret_string = jsonencode(local.bodmis_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# OASys Source Secrets
resource "aws_secretsmanager_secret" "oasys" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  count = local.is_dev_or_test ? 1 : 0

  name = "external/${local.project}-oasys-source-secret"

  tags = merge(
    local.all_tags,
    {
      Name          = "external/${local.project}-oasys-source-secret"
      Resource_Type = "Secrets"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "oasys" {
  count = local.is_dev_or_test ? 1 : 0

  secret_id     = aws_secretsmanager_secret.oasys[0].id
  secret_string = jsonencode(local.oasys_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# ONR Source Secrets
resource "aws_secretsmanager_secret" "onr" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  count = local.is_dev_or_test ? 1 : 0

  name = "external/${local.project}-onr-source-secret"

  tags = merge(
    local.all_tags,
    {
      Name          = "external/${local.project}-onr-source-secret"
      Resource_Type = "Secrets"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "onr" {
  count = local.is_dev_or_test ? 1 : 0

  secret_id     = aws_secretsmanager_secret.onr[0].id
  secret_string = jsonencode(local.onr_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}


# DPS Source Secrets
# PlaceHolder Secrets
resource "aws_secretsmanager_secret" "dps" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

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

# AWS Secrets Manager for Operational DB Credentials

resource "random_password" "operational_db_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "operational_db_secret" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name        = "${local.project}-rds-operational-db-secret"
  description = "Secret for RDS master username and password"

  tags = {
    Name = "${local.project}-rds-operational-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "operational_db_secret_version" {
  secret_id = aws_secretsmanager_secret.operational_db_secret.id

  secret_string = jsonencode({
    username = "dpradmin"
    password = random_password.operational_db_password.result
  })
}

# AWS Secrets Manager for Transfer Component Role Credentials

resource "random_password" "transfer_component_role_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "transfer_component_role_secret" {
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"

  name        = "${local.project}-rds-transfer-component-role-secret"
  description = "Secret for transfer-component-role username and password"

  tags = {
    Name = "${local.project}-rds-transfer-component-role-secret"
  }
}

resource "aws_secretsmanager_secret_version" "transfer_component_role_secret_version" {
  secret_id = aws_secretsmanager_secret.transfer_component_role_secret.id

  secret_string = jsonencode({
    username = "transfer-component-role"
    password = random_password.transfer_component_role_password.result
  })
}

# Operational DataStore Access Secrets

# Incident Reporting
resource "aws_secretsmanager_secret" "ods_dps_inc_reporting_access" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "dpr-ods-dps-inc-reporting-${local.env}"
  tags = merge(
    local.all_tags,
    {
      Name          = "dpr-ods-dps-inc-reporting-${local.env}"
      Resource_Type = "Secrets"
      Jira          = "DPR-1751"
    }
  )
}

resource "aws_secretsmanager_secret_version" "ods_dps_inc_reporting_access" {
  secret_id     = aws_secretsmanager_secret.ods_dps_inc_reporting_access.id
  secret_string = jsonencode(local.ods_access_secret_placeholder)
}
