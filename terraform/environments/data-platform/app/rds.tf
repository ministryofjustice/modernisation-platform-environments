resource "aws_db_subnet_group" "app" {
  name       = local.component_name
  subnet_ids = data.aws_subnets.eks-data.ids
}

resource "aws_db_parameter_group" "app" {
  name        = "${local.component_name}-postgres17"
  family      = "postgres17"
  description = "Parameter group for ${local.component_name} PostgreSQL 17"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "app" {
  identifier = local.component_name

  engine                      = "postgres"
  engine_version              = local.environment_configuration.rds_engine_version
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  apply_immediately           = false

  instance_class        = local.environment_configuration.rds_instance_class
  allocated_storage     = local.environment_configuration.rds_allocated_storage
  max_allocated_storage = local.environment_configuration.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = module.app_rds_kms_key.key_arn

  db_name                     = "app"
  username                    = "app"
  password_wo                 = random_password.rds.result
  password_wo_version         = 1
  manage_master_user_password = null

  multi_az               = local.environment_configuration.rds_multi_az
  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.app.name
  publicly_accessible    = false

  backup_retention_period = local.environment_configuration.rds_backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:03:30-Mon:04:30"
  copy_tags_to_snapshot   = true

  iam_database_authentication_enabled = true

  monitoring_interval = local.environment_configuration.rds_monitoring_interval
  monitoring_role_arn = local.environment_configuration.rds_monitoring_interval == 0 ? null : aws_iam_role.rds_enhanced_monitoring[0].arn

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = module.app_rds_kms_key.key_arn
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection       = local.is-production
  skip_final_snapshot       = !local.is-production
  final_snapshot_identifier = "${local.component_name}-final"
}

module "app_rds_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/rds"

  secret_string = jsonencode({
    username = aws_db_instance.app.username
    password = random_password.rds.result
    host     = aws_db_instance.app.address
    port     = tostring(aws_db_instance.app.port)
    dbname   = aws_db_instance.app.db_name
  })
}
