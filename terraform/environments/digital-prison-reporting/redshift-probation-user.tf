# Redshift Probation User Configuration
# Created: 2026-05-14
# Purpose: Create a separate database user for probation team access
#          to the same Redshift cluster and datamart database

# Generate random password for probation user
resource "random_password" "redshift_probation_password" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = false
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

# Stored procedure to create user and grant all permissions (idempotent)
resource "aws_redshiftdata_statement" "setup_probation_user" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "setup-probation-user-${local.environment}"

  sql = <<-SQL
    DO $$
    BEGIN
      -- Create user if it doesn't exist
      IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'probation_mi_app') THEN
        CREATE USER probation_mi_app WITH PASSWORD '${random_password.redshift_probation_password.result}';
        RAISE INFO 'User probation_mi_app created successfully';
      ELSE
        RAISE INFO 'User probation_mi_app already exists, skipping creation';
      END IF;

      -- Public Schema - Read-only access
      GRANT USAGE ON SCHEMA public TO probation_mi_app;
      GRANT SELECT ON ALL TABLES IN SCHEMA public TO probation_mi_app;
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO probation_mi_app;

      -- Reports Schema - CREATE and full DML access
      GRANT USAGE, CREATE ON SCHEMA reports TO probation_mi_app;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA reports TO probation_mi_app;
      ALTER DEFAULT PRIVILEGES IN SCHEMA reports GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO probation_mi_app;

      -- Admin Schema - INSERT and SELECT access
      GRANT USAGE ON SCHEMA admin TO probation_mi_app;
      GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA admin TO probation_mi_app;
      ALTER DEFAULT PRIVILEGES IN SCHEMA admin GRANT SELECT, INSERT ON TABLES TO probation_mi_app;

      -- Product_ Schema - Full DML access
      GRANT USAGE ON SCHEMA product_ TO probation_mi_app;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA product_ TO probation_mi_app;
      ALTER DEFAULT PRIVILEGES IN SCHEMA product_ GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO probation_mi_app;

      RAISE INFO 'All permissions granted successfully to probation_mi_app';
    END
    $$;
  SQL
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
