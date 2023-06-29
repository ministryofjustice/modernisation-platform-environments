#### This file can be used to store secrets specific to the member account ####

# Nomis Source Secrets
resource "aws_secretsmanager_secret" "nomis" {
  name = "external/${local.project}-nomis-source-secrets"
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
    name = "dpr-redshift-sqlworkbench-${local.project}"

    tags = {
        Redshift        = "redshift"
    }
}

#Redshift secrets and placeholders
resource "aws_secretsmanager_secret_version" "redshift" {
  secret_id     = aws_secretsmanager_secret.redshift.id
  secret_string = jsonencode(local.redshift_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }
}