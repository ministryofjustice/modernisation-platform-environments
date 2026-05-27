# Redshift Probation User Configuration
# Created: 2026-05-14
# Purpose: Create a separate database user for probation team access
#          to the same Redshift cluster and datamart database

# Generate random password for probation user (with lifecycle to prevent changes)
resource "random_password" "redshift_probation_password" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = false

  # Prevent password from regenerating on every terraform apply
  keepers = {
    version = "1"  # Only change this value if you want to rotate the password
  }
}

# Create secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "redshift_probation_user" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Manual rotation for application user"
  #checkov:skip=CKV_AWS_149: "Using KMS encryption via kms_key_id"

  description = "Redshift connect details for probation user"
  name        = "${local.project}-redshift-probation-secret-${local.environment}"
  kms_key_id  = aws_kms_key.redshift-kms-key.arn

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-redshift-probation-secret-${local.environment}"
      dpr-resource-type = "Secret"
      dpr-jira          = "DPR-PROBATION"
    }
  )
}

# Store credentials in secret
resource "aws_secretsmanager_secret_version" "redshift_probation_user" {
  secret_id = aws_secretsmanager_secret.redshift_probation_user.id
  secret_string = jsonencode({
    username            = "probation_mi_app"
    password            = random_password.redshift_probation_password.result
    engine              = "redshift"
    host                = module.datamart.cluster_endpoint
    port                = "5439"
    dbClusterIdentifier = module.datamart.cluster_identifier
    database            = "datamart"
  })
}

# Create Database User using Redshift Data API


# Create generic stored procedure to safely create any user (idempotent and reusable)
resource "aws_redshiftdata_statement" "create_user_procedure" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "create-user-procedure-${local.environment}"

  sql = <<-SQL
    CREATE OR REPLACE PROCEDURE create_user(
      user_name VARCHAR(128),
      user_pwd VARCHAR(256)
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
      -- Check if user already exists
      IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = user_name) THEN
        -- Create user only if it doesn't exist
        EXECUTE 'CREATE USER ' || user_name || ' WITH PASSWORD ''' || user_pwd || '''';
        RAISE INFO 'User % created successfully', user_name;
      ELSE
        RAISE INFO 'User % already exists, skipping creation', user_name;
      END IF;
    END;
    $$;
  SQL
}

# Call the stored procedure to create the probation user
resource "aws_redshiftdata_statement" "create_probation_user" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "call-create-probation-user-${local.environment}"

  sql = "CALL create_user('probation_mi_app', '${random_password.redshift_probation_password.result}');"

  depends_on = [aws_redshiftdata_statement.create_user_procedure]
}

# Public Schema - Read-only access

resource "aws_redshiftdata_statement" "grant_probation_usage_public" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-usage-public-${local.environment}"
  sql                = "GRANT USAGE ON SCHEMA public TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.create_probation_user]
}

resource "aws_redshiftdata_statement" "grant_probation_select_public" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-select-public-${local.environment}"
  sql                = "GRANT SELECT ON ALL TABLES IN SCHEMA public TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_usage_public]
}

resource "aws_redshiftdata_statement" "grant_probation_future_select_public" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-public-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_select_public]
}

# Reports Schema - CREATE and SELECT only

resource "aws_redshiftdata_statement" "grant_probation_usage_reports" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-usage-reports-${local.environment}"
  sql                = "GRANT USAGE ON SCHEMA reports TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.create_probation_user]
}

resource "aws_redshiftdata_statement" "grant_probation_create_reports" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-create-reports-${local.environment}"
  sql                = "GRANT CREATE ON SCHEMA reports TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_usage_reports]
}

resource "aws_redshiftdata_statement" "grant_probation_select_reports" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-select-reports-${local.environment}"
  sql                = "GRANT SELECT ON ALL TABLES IN SCHEMA reports TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_create_reports]
}

resource "aws_redshiftdata_statement" "grant_probation_future_select_reports" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-select-reports-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA reports GRANT SELECT ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_select_reports]
}

# Admin Schema - INSERT and SELECT only

resource "aws_redshiftdata_statement" "grant_probation_usage_admin" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-usage-admin-${local.environment}"
  sql                = "GRANT USAGE ON SCHEMA admin TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.create_probation_user]
}

resource "aws_redshiftdata_statement" "grant_probation_insert_admin" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-insert-admin-${local.environment}"
  sql                = "GRANT INSERT ON ALL TABLES IN SCHEMA admin TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_usage_admin]
}

resource "aws_redshiftdata_statement" "grant_probation_select_admin" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-select-admin-${local.environment}"
  sql                = "GRANT SELECT ON ALL TABLES IN SCHEMA admin TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_insert_admin]
}

resource "aws_redshiftdata_statement" "grant_probation_future_insert_admin" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-insert-admin-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA admin GRANT INSERT ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_select_admin]
}

resource "aws_redshiftdata_statement" "grant_probation_future_select_admin" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-select-admin-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA admin GRANT SELECT ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_future_insert_admin]
}


# Product_ Schema - INSERT, UPDATE, DELETE, and SELECT

resource "aws_redshiftdata_statement" "grant_probation_usage_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-usage-product-${local.environment}"
  sql                = "GRANT USAGE ON SCHEMA product_ TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.create_probation_user]
}

resource "aws_redshiftdata_statement" "grant_probation_insert_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-insert-product-${local.environment}"
  sql                = "GRANT INSERT ON ALL TABLES IN SCHEMA product_ TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_usage_product]
}

resource "aws_redshiftdata_statement" "grant_probation_update_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-update-product-${local.environment}"
  sql                = "GRANT UPDATE ON ALL TABLES IN SCHEMA product_ TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_insert_product]
}

resource "aws_redshiftdata_statement" "grant_probation_delete_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-delete-product-${local.environment}"
  sql                = "GRANT DELETE ON ALL TABLES IN SCHEMA product_ TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_update_product]
}

resource "aws_redshiftdata_statement" "grant_probation_select_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-select-product-${local.environment}"
  sql                = "GRANT SELECT ON ALL TABLES IN SCHEMA product_ TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_delete_product]
}

resource "aws_redshiftdata_statement" "grant_probation_future_insert_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-insert-product-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA product_ GRANT INSERT ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_select_product]
}

resource "aws_redshiftdata_statement" "grant_probation_future_update_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-update-product-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA product_ GRANT UPDATE ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_future_insert_product]
}

resource "aws_redshiftdata_statement" "grant_probation_future_delete_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-delete-product-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA product_ GRANT DELETE ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_future_update_product]
}

resource "aws_redshiftdata_statement" "grant_probation_future_select_product" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-select-product-${local.environment}"
  sql                = "ALTER DEFAULT PRIVILEGES IN SCHEMA product_ GRANT SELECT ON TABLES TO probation_mi_app;"
  depends_on         = [aws_redshiftdata_statement.grant_probation_future_delete_product]
}

# Outputs for reference

output "probation_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing probation user credentials"
  value       = aws_secretsmanager_secret.redshift_probation_user.arn
  sensitive   = false
}

output "probation_user_secret_name" {
  description = "Name of the Secrets Manager secret containing probation user credentials"
  value       = aws_secretsmanager_secret.redshift_probation_user.name
  sensitive   = false
}

output "probation_username" {
  description = "Redshift username for probation user"
  value       = "probation_mi_app"
  sensitive   = false
}
