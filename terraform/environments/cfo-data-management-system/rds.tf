# MP RDS Instance Module - https://github.com/ministryofjustice/modernisation-platform-terraform-rds-instance
module "rds" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-rds-instance.git?ref=v0.5.0"

  application_name = "${local.application_name_short}-${local.environment}"
  tags             = local.tags

  # Networking
  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = data.aws_subnets.shared-data.ids
  db_port    = 1433

  # Engine
  db_engine                 = "sqlserver-se"
  db_engine_version         = "16.00.4250.1.v1"
  db_parameter_group_family = "sqlserver-se-16.0"

  # Storage
  db_instance_class    = local.application_data.accounts[local.environment].rds.db_instance_class
  db_allocated_storage = local.application_data.accounts[local.environment].rds.db_allocated_storage

  # Credentials
  db_username = "dbadmin"

  # Encryption
  kms_key_id = data.aws_kms_key.rds_shared.arn

  # Availability & maintenance
  multi_az            = local.application_data.accounts[local.environment].rds.db_multi_az
  deletion_protection = local.is-production
  backup_retention_period = local.is-production ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  ca_cert_identifier      = "rds-ca-rsa2048-g1"

  # Snapshots
  skip_final_snapshot = local.application_data.accounts[local.environment].rds.skip_final_snapshot

  # Monitoring & performance
  performance_insights_enabled = local.application_data.accounts[local.environment].rds.performance_insights_enabled
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds-enhanced-monitoring.arn

  # CloudWatch log retention
  cloudwatch_log_retention_days = local.is-production ? 90 : 30

  # XSIAM logging - Opt out
  opt_in_xsiam_logging = false
}
