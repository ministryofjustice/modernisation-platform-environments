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
  name = "dpr-redshift-sqlworkbench-secrets-${local.env}"

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
  secret_string = jsonencode(local.redshift_secrets_placeholder)
}
