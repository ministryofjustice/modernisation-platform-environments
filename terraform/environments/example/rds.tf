# Example code to build an RDS database - based on mysql but could be :
# Amazon Aurora, PostgreSQL, MariaDB, Oracle, MicroSoft SQL Server. These will require the correct version
# The local.application_data is picked from local but set up in application_variables.json
# Set these up in there and make sure the local points to that location


resource "aws_db_instance" "Example-RDS" {
  engine                      = "mysql"
  engine_version              = "5.7"
  auto_minor_version_upgrade  = true
  instance_class              = local.application_data.accounts[local.environment].db_instance_class
  db_name                     = "${local.application_name}${local.environment}database"
  identifier                  = "${local.application_name}-${local.environment}-database"
  username                    = local.application_data.accounts[local.environment].db_user
  password                    = aws_secretsmanager_secret_version.db_password.secret_string
  parameter_group_name        = "default.mysql5.7"
  skip_final_snapshot         = local.application_data.accounts[local.environment].skip_final_snapshot
  allocated_storage           = local.application_data.accounts[local.environment].db_allocated_storage
  max_allocated_storage       = local.application_data.accounts[local.environment].db_max_allocated_storage
  maintenance_window          = local.application_data.accounts[local.environment].maintenance_window
  allow_major_version_upgrade = local.application_data.accounts[local.environment].allow_major_version_upgrade
  backup_window               = local.application_data.accounts[local.environment].backup_window
  backup_retention_period     = local.application_data.accounts[local.environment].retention_period
  #checkov:skip=CKV_AWS_133: "backup_retention enabled, can be edited it application_variables.json"
  iam_database_authentication_enabled = local.application_data.accounts[local.environment].db_iam_database_authentication_enabled
  #checkov:skip=CKV_AWS_161: "iam auth enabled, but optional"
  multi_az                    = local.application_data.accounts[local.environment].db_multi_az
  #checkov:skip=CKV_AWS_157: "multi-az enabled, but optional"
  monitoring_interval         = local.application_data.accounts[local.environment].db_monitoring_interval
  #checkov:skip=CKV_AWS_118: "enhanced monitoring is enabled, but optional"
  storage_encrypted           = true
  performance_insights_enabled = local.application_data.accounts[local.environment].db_performance_insights_enabled
  performance_insights_kms_key_id = "" #tfsec:ignore:aws-rds-enable-performance-insights-encryption Left empty so that it will run, however should be populated with real key in scenario.
  enabled_cloudwatch_logs_exports = local.application_data.accounts[local.environment].db_enabled_cloudwatch_logs_exports
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-example", local.application_name, local.environment)) }
  )
}
