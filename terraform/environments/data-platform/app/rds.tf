module "rds" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=bc8c1e240a98fd54a12c61c70de91cbabec71863" # v7.2.0

  identifier = local.component_name

  engine               = "postgres"
  engine_version       = local.environment_configuration.rds_engine_version
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = local.environment_configuration.rds_instance_class

  allocated_storage     = local.environment_configuration.rds_allocated_storage
  max_allocated_storage = local.environment_configuration.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = module.rds_encryption.key_arn

  db_name                     = "app"
  username                    = "app"
  password_wo                 = random_password.rds.result
  password_wo_version         = 1
  manage_master_user_password = false

  multi_az               = local.environment_configuration.rds_multi_az
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds.id]

  create_db_subnet_group = true
  subnet_ids             = data.aws_subnets.eks_data.ids

  parameter_group_name            = local.component_name
  parameter_group_use_name_prefix = false
  parameters = [
    {
      name  = "rds.force_ssl"
      value = "1"
    }
  ]

  iam_database_authentication_enabled = true

  monitoring_interval    = local.environment_configuration.rds_monitoring_interval
  create_monitoring_role = local.environment_configuration.rds_monitoring_interval != 0
  monitoring_role_name   = "${local.component_name}-rds-monitoring"

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = module.rds_encryption.key_arn
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = local.environment_configuration.rds_backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:03:30-Mon:04:30"
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true
  apply_immediately          = false

  deletion_protection = local.is-production
  skip_final_snapshot = !local.is-production
}

resource "random_password" "rds" {
  length  = 32
  special = false
}
