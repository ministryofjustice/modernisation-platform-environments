#### This file can be used to store secrets specific to the member account ####

# Nomis Source Secrets
resource "aws_secretsmanager_secret" "nomis" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "external/${local.project}-nomis-source-secrets"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-nomis-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR-XXXX"
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
      dpr-name          = "external/${local.project}-nomis-testing-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-1159"
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
      dpr-name          = "external/${local.project}-bodmis-source-secret"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-721"
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
  count = local.is-test ? 1 : 0

  name = "external/${local.project}-oasys-source-secret"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-oasys-source-secret"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-XXX"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "oasys" {
  count = local.is-test ? 1 : 0

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
  count = local.is-test ? 1 : 0

  name = "external/${local.project}-onr-source-secret"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-onr-source-secret"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-XXX"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "onr" {
  count = local.is-test ? 1 : 0

  secret_id     = aws_secretsmanager_secret.onr[0].id
  secret_string = jsonencode(local.onr_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# nDelius Source Secrets
resource "aws_secretsmanager_secret" "ndelius" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  count = local.is-test ? 1 : 0

  name = "external/${local.project}-ndelius-source-secret"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-ndelius-source-secret"
      dpr-resource-type = "Secrets"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "ndelius" {
  count = local.is-test ? 1 : 0

  secret_id     = aws_secretsmanager_secret.ndelius[0].id
  secret_string = jsonencode(local.ndelius_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# ndmis Source Secrets
resource "aws_secretsmanager_secret" "ndmis" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  count = local.is_non_prod ? 1 : 0

  name = "external/${local.project}-ndmis-source-secret"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-ndmis-source-secret"
      dpr-resource-type = "Secrets"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "ndmis" {
  count = local.is_non_prod ? 1 : 0

  secret_id     = aws_secretsmanager_secret.ndmis[0].id
  secret_string = jsonencode(local.ndmis_secrets_placeholder)

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
      dpr-name          = "external/${local.project}-${each.value}-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-source        = "DPS"
      dpr-domain        = each.value
      dpr-jira          = "DPR2-341"
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
      dpr-name          = "dpr-redshift-sqlworkbench-${local.env}"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR-XXXX"
      dpr-service       = "redshift"
      # Tag required to make the secret available in Redshift Query Editor v2
      Redshift          = "redshift"
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
      dpr-resource-group = "monitoring"
      dpr-jira           = "DPR-569"
      dpr-resource-type  = "Secret"
      dpr-name           = "${local.project}-slack-alerts-url-${local.environment}"
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
      dpr-resource-group = "monitoring"
      dpr-jira           = "DPR-569"
      dpr-resource-type  = "Secret"
      dpr-name           = "${local.project}-pagerduty-integration-key-${local.environment}"
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
      dpr-resource-group = "monitoring"
      dpr-jira           = "DPR2-69"
      dpr-resource-type  = "Secret"
      dpr-name           = "${local.project}-sonatype-registry-${local.environment}"
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
      dpr-name          = "external/busobj-converter/biprws"
      dpr-resource-type = "Secrets"
      dpr-source        = "NART"
      dpr-jira          = "DPR2-527"
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
      dpr-name          = "external/cloud_platform/k8s_auth"
      dpr-resource-type = "Secrets"
      dpr-source        = "CP"
      dpr-jira          = "DPR2-768"
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
      dpr-name          = "external/cloud_platform/bodmis_k8s_auth"
      dpr-resource-type = "Secrets"
      dpr-source        = "CP"
      dpr-jira          = "DPR2-908"
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
      dpr-name          = "external/cloud_platform/k8s_auth"
      dpr-resource-type = "Secrets"
      dpr-source        = "Analytics-Platform"
      dpr-jira          = "DPR2-751"
    }
  )

  lifecycle {
    ignore_changes = [tags]
  }
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
    dpr-name = "${local.project}-rds-operational-db-secret"
  }

  lifecycle {
    ignore_changes = [tags]
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
    dpr-name = "${local.project}-rds-transfer-component-role-secret"
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
      dpr-name          = "dpr-ods-dps-inc-reporting-${local.env}"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR-1751"
    }
  )

}

resource "aws_secretsmanager_secret_version" "ods_dps_inc_reporting_access" {
  secret_id     = aws_secretsmanager_secret.ods_dps_inc_reporting_access.id
  secret_string = jsonencode(local.ods_access_secret_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# Windows EC2 RDP Admin Password
resource "aws_secretsmanager_secret" "dpr_windows_rdp_credentials" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "compute/dpr-windows-rdp-credentials"
  tags = merge(
    local.all_tags,
    {
      dpr-name          = "compute/dpr-windows-rdp-credentials"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-1980"
    }
  )

}

resource "aws_secretsmanager_secret_version" "dpr_windows_rdp_credentials" {
  secret_id     = aws_secretsmanager_secret.dpr_windows_rdp_credentials.id
  secret_string = jsonencode(local.dpr_windows_rdp_credentials_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}

# Nomis Test Source Secrets (for Unit Test)
resource "aws_secretsmanager_secret" "dpr-test" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  count = local.is_dev_or_test ? 1 : 0

  name = "external/${local.project}-dps-test-db-source-secrets"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-dps-test-db-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DPR2-2072"
    }
  )
}

# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "dpr-test" {
  count = local.is_dev_or_test ? 1 : 0

  secret_id     = aws_secretsmanager_secret.dpr-test[0].id
  secret_string = jsonencode(local.dps_secrets_placeholder) # Uses the DPS secret placeholder format

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}
