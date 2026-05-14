###############################################################################
# Redshift Probation User Configuration
# Created: 2026-05-14
# Purpose: Create a separate database user for probation team access
#          to the same Redshift cluster and datamart database
###############################################################################

# Generate random password for probation user (matching dpruser pattern)
resource "random_password" "redshift_probation_password" {
  length      = 16 # Same as dpruser
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = false # NO special chars - matches dpruser pattern
}

# Create secret in AWS Secrets Manager (matching dpruser pattern)
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

# Store credentials in secret (matching dpruser secret structure)
resource "aws_secretsmanager_secret_version" "redshift_probation_user" {
  secret_id = aws_secretsmanager_secret.redshift_probation_user.id
  secret_string = jsonencode({
    username            = "probation_user"
    password            = random_password.redshift_probation_password.result
    engine              = "redshift"
    host                = module.datamart.endpoint
    port                = "5439"
    dbClusterIdentifier = module.datamart.cluster_identifier
    database            = "datamart" # Same database as dpruser
  })
}

###############################################################################
# Create Database User using Redshift Data API
###############################################################################

# Create the probation user in Redshift database
resource "aws_redshiftdata_statement" "create_probation_user" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser" # Use master user to create new user
  statement_name     = "create-probation-user-${local.environment}"

  sql = "CREATE USER probation_user WITH PASSWORD '${random_password.redshift_probation_password.result}';"

  depends_on = [
    module.datamart,
    random_password.redshift_probation_password
  ]
}

# Grant USAGE permission on public schema
resource "aws_redshiftdata_statement" "grant_probation_usage" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-usage-${local.environment}"

  sql = "GRANT USAGE ON SCHEMA public TO probation_user;"

  depends_on = [
    aws_redshiftdata_statement.create_probation_user
  ]
}

# Grant SELECT permission on all existing tables
resource "aws_redshiftdata_statement" "grant_probation_select" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-select-${local.environment}"

  sql = "GRANT SELECT ON ALL TABLES IN SCHEMA public TO probation_user;"

  depends_on = [
    aws_redshiftdata_statement.grant_probation_usage
  ]
}

# Grant SELECT permission on future tables (important for new tables)
resource "aws_redshiftdata_statement" "grant_probation_future_select" {
  cluster_identifier = module.datamart.cluster_identifier
  database           = "datamart"
  db_user            = "dpruser"
  statement_name     = "grant-probation-future-${local.environment}"

  sql = "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO probation_user;"

  depends_on = [
    aws_redshiftdata_statement.grant_probation_select
  ]
}

###############################################################################
# Outputs for reference
###############################################################################

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
  value       = "probation_user"
  sensitive   = false
}
