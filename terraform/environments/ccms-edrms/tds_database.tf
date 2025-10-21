resource "aws_db_subnet_group" "tds" {
  name       = "${local.application_name}-tds-subnet-group"
  subnet_ids = data.aws_subnets.shared-data.ids
}

resource "aws_db_option_group" "tds_oracle_19" {
  name_prefix          = "${local.application_name}-tds-db-option-group"
  engine_name          = "oracle-se2"
  major_engine_version = "19"

  option {
    option_name = "S3_INTEGRATION"
    port        = 0
    version     = "1.0"
  }
}

resource "aws_db_instance" "tds_db" {
  identifier                          = "${local.application_name}-tds-db"
  allocated_storage                   = local.application_data.accounts[local.environment].tds_db_storage_gb
  auto_minor_version_upgrade          = true
  storage_type                        = "gp2"
  engine                              = "oracle-se2"
  engine_version                      = "19.0.0.0.ru-2025-07.rur-2025-07.r1"
  instance_class                      = local.application_data.accounts[local.environment].tds_db_instance_type
  multi_az                            = local.application_data.accounts[local.environment].tds_db_deploy_to_multi_azs
  db_name                             = "EDRMSTDS"
  username                            = local.application_data.accounts[local.environment].tds_db_user
  password                            = data.aws_secretsmanager_secret_version.spring_datasource_password.secret_string
  port                                = "1521"
  kms_key_id                          = data.aws_kms_key.rds_shared.arn
  storage_encrypted                   = true
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false
  vpc_security_group_ids = [
    aws_security_group.tds_db.id
  ]
  backup_retention_period = 30
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  character_set_name      = "AL32UTF8"
  deletion_protection     = local.application_data.accounts[local.environment].tds_db_deletion_protection
  db_subnet_group_name    = aws_db_subnet_group.tds.id
  option_group_name       = aws_db_option_group.tds_oracle_19.id
  license_model           = "bring-your-own-license"
  tags = merge(
    local.tags,
    { instance-scheduling = "skip-scheduling" }
  )
  enabled_cloudwatch_logs_exports = [
    "alert",
    "audit",
    "listener"
  ]

  timeouts {
    create = "40m"
    delete = "40m"
    update = "80m"
  }
}
