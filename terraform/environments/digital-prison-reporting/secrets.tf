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

# Probation Source Secrets
resource "aws_secretsmanager_secret" "probation" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  for_each = toset(local.probation_domains_list)
  name     = "external/${local.project}-${each.value}-source-secrets"

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "external/${local.project}-${each.value}-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-source        = "Probation"
      dpr-domain        = each.value
      dpr-jira          = "PDHD-1111"
    }
  )
}

resource "aws_secretsmanager_secret_version" "probation" {
  for_each = toset(local.probation_domains_list)

  secret_id     = aws_secretsmanager_secret.probation[each.key].id
  secret_string = jsonencode(local.probation_secrets_placeholder)

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
      Redshift          = "True" # Required for Redshift Query Editor
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

# Cross-account secrets for Cloud Platform access
# These secrets are shared with the Cloud Platform account (754256621582) to allow
# CP services to access DPR database credentials without direct cross-account role assumption

# KMS key for cross-account secret encryption (shared across all cross-account secrets)
# DHS-643
resource "aws_kms_key" "crossaccount_secret" {
  #checkov:skip=CKV_AWS_33
  #checkov:skip=CKV_AWS_227
  #checkov:skip=CKV_AWS_7

  description         = "Encryption key for cross-account secrets shared with Cloud Platform"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.crossaccount_secret_kms.json
  is_enabled          = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "crossaccount-secrets-kms-${local.env}"
      dpr-resource-type = "KMS Key"
      dpr-jira          = "DHS-643"
    }
  )
}

# KMS key policy - allows both MP account root and CP role to decrypt
# DHS-643
data "aws_iam_policy_document" "crossaccount_secret_kms" {
  # Allow MP account root full access
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109
    #checkov:skip=CKV_AWS_110
    #checkov:skip=CKV_AWS_358
    #checkov:skip=CKV_AWS_107
    #checkov:skip=CKV_AWS_1
    #checkov:skip=CKV_AWS_283
    #checkov:skip=CKV_AWS_49
    #checkov:skip=CKV_AWS_108
    #checkov:skip=CKV_AWS_356

    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow Cloud Platform account to decrypt secret
  # The IAM policy on the CP role will control which specific roles can use this key
  # DHS-643
  statement {
    sid    = "AllowCloudPlatformAccountToDecryptSecret"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:root"]
    }
  }
}

resource "aws_kms_alias" "crossaccount_secret_kms_alias" {
  name          = "alias/crossaccount-secrets-kms-${local.env}"
  target_key_id = aws_kms_key.crossaccount_secret.arn
}

# Assessment View Database Secret for Cloud Platform
# DHS-643
resource "aws_secretsmanager_secret" "dpr_crossaccount_assessment_view" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  count = local.is_dev_or_test ? 1 : 0

  name                    = "${local.env}/dpr-crossaccount-assessment-view-db"
  description             = "DPR Assessment View database credentials shared with Cloud Platform for cross-account access"
  kms_key_id              = aws_kms_key.crossaccount_secret.arn
  recovery_window_in_days = 0

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.env}/dpr-crossaccount-assessment-view-db"
      dpr-resource-type = "Secrets"
      dpr-jira          = "DHS-643"
      dpr-shared-with   = "Cloud Platform"
      dpr-database      = "assessment-view"
    }
  )
}

# Stable random password for the Assessment View DB secret
# Generated once on first apply; ignore_changes on secret_string prevents it being rotated on every apply
resource "random_password" "dpr_crossaccount_assessment_view_db" {
  length  = 32
  special = false
}

# Secret version - merges connection details with the generated password
resource "aws_secretsmanager_secret_version" "dpr_crossaccount_assessment_view" {
  count = local.is_dev_or_test ? 1 : 0

  secret_id = aws_secretsmanager_secret.dpr_crossaccount_assessment_view[0].id
  secret_string = jsonencode(merge(
    local.dpr_crossaccount_assessment_view_secrets_placeholder,
    { password = random_password.dpr_crossaccount_assessment_view_db.result }
  ))

  lifecycle {
    ignore_changes = [secret_string] 
  }
}

# Resource policy for the secret - allows CP account to read
# The IAM policy on the CP role will control which specific roles can read this secret
resource "aws_secretsmanager_secret_policy" "dpr_crossaccount_assessment_view" {
  count = local.is_dev_or_test ? 1 : 0

  secret_arn = aws_secretsmanager_secret.dpr_crossaccount_assessment_view[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudPlatformAccountToReadSecret"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::754256621582:root"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}
