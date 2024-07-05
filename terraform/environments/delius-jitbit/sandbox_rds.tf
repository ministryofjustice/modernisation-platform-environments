resource "aws_security_group" "database_security_group_sandbox" {
  count = local.is-development ? 1 : 0

  name        = "${local.application_name}-sandbox-database-security-group"
  description = "controls access to db"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Allow MSSQL traffic"
    from_port   = 1433
    to_port     = 1433
    security_groups = [
      aws_security_group.jitbit_sandbox[0].id,
      module.bastion_linux.bastion_security_group
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-sandbox-database_security_group-security-group"
    }
  )
}

resource "aws_db_instance" "jitbit_sandbox" {
  count = local.is-development ? 1 : 0

  engine         = "sqlserver-se"
  license_model  = "license-included"
  engine_version = local.application_data.accounts["sandbox"].db_engine_version
  instance_class = local.application_data.accounts["sandbox"].db_instance_class
  identifier     = "${local.application_name}-sandbox-database"
  username       = local.application_data.accounts["sandbox"].db_user

  manage_master_user_password = true

  snapshot_identifier = try(local.application_data.accounts["sandbox"].db_snapshot_identifier, null)

  # tflint-ignore: aws_db_instance_default_parameter_group
  parameter_group_name        = "default.sqlserver-se-15.0"
  ca_cert_identifier          = local.application_data.accounts["sandbox"].db_ca_cert_identifier
  deletion_protection         = local.application_data.accounts["sandbox"].db_deletion_protection
  delete_automated_backups    = local.application_data.accounts["sandbox"].db_delete_automated_backups
  skip_final_snapshot         = local.application_data.accounts["sandbox"].db_skip_final_snapshot
  final_snapshot_identifier   = !local.skip_final_snapshot ? "${local.application_name}-sandbox-database-final-snapshot" : null
  allocated_storage           = local.application_data.accounts["sandbox"].db_allocated_storage
  max_allocated_storage       = local.application_data.accounts["sandbox"].db_max_allocated_storage
  storage_type                = local.application_data.accounts["sandbox"].db_storage_type
  maintenance_window          = local.application_data.accounts["sandbox"].db_maintenance_window
  auto_minor_version_upgrade  = local.application_data.accounts["sandbox"].db_auto_minor_version_upgrade
  allow_major_version_upgrade = local.application_data.accounts["sandbox"].db_allow_major_version_upgrade
  backup_window               = local.application_data.accounts["sandbox"].db_backup_window
  backup_retention_period     = local.application_data.accounts["sandbox"].db_retention_period
  #checkov:skip=CKV_AWS_133: "backup_retention enabled, can be edited it application_variables.json"
  iam_database_authentication_enabled = local.application_data.accounts["sandbox"].db_iam_database_authentication_enabled
  #checkov:skip=CKV_AWS_161: "iam auth enabled, but optional"
  db_subnet_group_name   = aws_db_subnet_group.jitbit.id
  vpc_security_group_ids = [aws_security_group.database_security_group_sandbox[0].id]
  multi_az               = local.application_data.accounts["sandbox"].db_multi_az
  #checkov:skip=CKV_AWS_157: "multi-az enabled, but optional"
  storage_encrypted = true

  tags = merge(
    local.tags,
    {
      Name = lower(format("%s-%s-database", local.application_name, "sandbox"))
    }
  )
}
