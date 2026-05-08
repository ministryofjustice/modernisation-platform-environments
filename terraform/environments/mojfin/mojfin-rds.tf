resource "aws_db_parameter_group" "mojfin" {
  name        = "${local.application_name}-${local.environment}-parametergroup"
  family      = "oracle-se2-19"
  description = "${local.application_name}-${local.environment}-parametergroup"

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "8"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-parametergroup" },
    { "Keep" = "true" }
  )
}

resource "aws_db_option_group" "mojfin" {
  name                     = "${local.application_name}-${local.environment}-optiongroup"
  option_group_description = "MOJFIN DB - enables TIMEZONE"
  engine_name              = "oracle-se2"
  major_engine_version     = "19"

  option {
    option_name = "Timezone"
    option_settings {
      name  = "TIME_ZONE"
      value = "Europe/London"
    }
  }

  option {
    option_name = "S3_INTEGRATION"
    version     = "1.0"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-optiongroup" },
    { "Keep" = "true" }
  )
}

resource "aws_db_instance" "appdb1" {
  allocated_storage               = local.application_data.accounts[local.environment].allocated_storage_size
  db_name                         = upper(local.application_name)
  identifier                      = local.application_name
  engine                          = local.engine
  engine_version                  = local.engine_version
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  performance_insights_enabled    = true
  instance_class                  = local.instance_class
  auto_minor_version_upgrade      = local.auto_minor_version_upgrade
  storage_type                    = local.storage_type
  backup_retention_period         = local.backup_retention_period
  backup_window                   = local.backup_window
  character_set_name              = local.character_set_name
  max_allocated_storage           = local.application_data.accounts[local.environment].max_allocated_storage_size
  username                        = local.username
  password                        = random_password.rds_password.result
  vpc_security_group_ids          = [aws_security_group.mojfin.id]
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name            = aws_db_parameter_group.mojfin.name
  db_subnet_group_name            = aws_db_subnet_group.mojfin.name
  maintenance_window              = local.maintenance_window
  license_model                   = "license-included"
  deletion_protection             = local.deletion_production
  copy_tags_to_snapshot           = true
  storage_encrypted               = true
  apply_immediately               = true
  # snapshot_identifier             = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id,local.application_data.accounts[local.environment].mojfinrdssnapshotid)
  kms_key_id         = data.aws_kms_key.rds_shared.arn
  multi_az           = true
  option_group_name  = aws_db_option_group.mojfin.name
  ca_cert_identifier = local.ca_cert_identifier

  # restore_to_point_in_time {
  #   restore_time = "2023-07-04T14:54:00Z"
  #   source_db_instance_identifier = local.application_name
  # }

  timeouts {
    create = "60m"
    delete = "2h"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}" },
    { "Keep" = "true" }
  )
}
