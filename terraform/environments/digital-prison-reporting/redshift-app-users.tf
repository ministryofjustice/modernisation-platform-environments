# Redshift users for the prisons and probation reporting apps, so that neither has to connect as the
# superuser. Each user's credentials are in its own secret. Their grants are made by the Redshift
# migrations in digital-prison-reporting-transfer-component.

locals {
  redshift_app_users = {
    prisons   = "prisons_mi_app"
    probation = "probation_mi_app"
  }
}

resource "random_password" "redshift_app_user" {
  for_each = local.redshift_app_users

  length      = 32
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
  special     = false
}

resource "aws_secretsmanager_secret" "redshift_app_user" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Manual rotation for application user"
  #checkov:skip=CKV_AWS_149: "Using KMS encryption via kms_key_id"
  for_each = local.redshift_app_users

  description = "Redshift connect details for ${each.value}"
  name        = "${local.project}-redshift-${each.key}-secret-${local.environment}"
  kms_key_id  = aws_kms_key.redshift-kms-key.arn

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-redshift-${each.key}-secret-${local.environment}"
      dpr-resource-type = "Secret"
      dpr-jira          = "DHS-942"
    }
  )
}

resource "aws_secretsmanager_secret_version" "redshift_app_user" {
  for_each = local.redshift_app_users

  secret_id = aws_secretsmanager_secret.redshift_app_user[each.key].id
  secret_string = jsonencode({
    username            = each.value
    password            = random_password.redshift_app_user[each.key].result
    engine              = "redshift"
    host                = module.datamart.cluster_endpoint
    port                = tostring(module.datamart.cluster_port)
    dbClusterIdentifier = module.datamart.cluster_identifier
    database            = module.datamart.cluster_database_name
  })
}

moved {
  from = aws_secretsmanager_secret.redshift_probation_user
  to   = aws_secretsmanager_secret.redshift_app_user["probation"]
}

moved {
  from = aws_secretsmanager_secret_version.redshift_probation_user
  to   = aws_secretsmanager_secret_version.redshift_app_user["probation"]
}

# Each statement runs when it's created and again whenever it's replaced, which any change to its SQL
# does, so all of them must be safe to run more than once. Redshift has no CREATE USER IF NOT EXISTS,
# so a procedure creates the user if it's missing, with its password disabled, and ALTER USER sets the
# password. The password is passed as an MD5 hash, so it never appears in plain text in Redshift's logs
# or system tables, or in the Data API's statement history.

resource "aws_redshiftdata_statement" "create_user_if_missing_procedure" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "create-user-if-missing-procedure-${local.environment}"

  sql = <<-SQL
    CREATE OR REPLACE PROCEDURE create_user_if_missing(user_name VARCHAR(128))
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = user_name) THEN
        EXECUTE 'CREATE USER ' || quote_ident(user_name) || ' PASSWORD DISABLE';
        RAISE INFO 'User % created', user_name;
      ELSE
        RAISE INFO 'User % already exists', user_name;
      END IF;
    END;
    $$;
  SQL
}

resource "aws_redshiftdata_statement" "create_app_user" {
  for_each = local.redshift_app_users

  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "create-${each.key}-app-user-${local.environment}"
  sql                = "CALL create_user_if_missing('${each.value}');"

  depends_on = [aws_redshiftdata_statement.create_user_if_missing_procedure]
}

resource "aws_redshiftdata_statement" "set_app_user_password" {
  for_each = local.redshift_app_users

  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "set-${each.key}-app-user-password-${local.environment}"
  # Redshift's MD5 form is 'md5' followed by the MD5 of the password and the user name concatenated
  sql = "ALTER USER ${each.value} PASSWORD 'md5${md5("${random_password.redshift_app_user[each.key].result}${each.value}")}';"

  depends_on = [aws_redshiftdata_statement.create_app_user]
}
