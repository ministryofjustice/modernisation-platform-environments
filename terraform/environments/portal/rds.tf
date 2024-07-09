locals {
  # General
  region = "eu-west-2"

  # RDS
  igdb_dbname                     = "IGDB"
  igdb_storage_size               = "200"
  igdb_auto_minor_version_upgrade = false
  igdb_backup_retention_period    = "35"
  igdb_character_set_name         = "AL32UTF8"
  igdb_instance_class             = "db.t3.large"
  igdb_engine                     = "oracle-ee"
  igdb_engine_version             = "19.0.0.0.ru-2024-04.rur-2024-04.r1"
  igdb_username                   = "admin"
  igdb_max_allocated_storage      = "3500"
  igdb_backup_window              = "22:00-01:00"
  igdb_maintenance_window         = "Mon:01:15-Mon:06:00"
  igdb_storage_type               = "gp2"
  iadb_dbname                     = "IADB"
  iadb_storage_size               = "200"
  iadb_auto_minor_version_upgrade = false
  iadb_backup_retention_period    = "35"
  iadb_character_set_name         = "AL32UTF8"
  iadb_instance_class             = "db.t3.large"
  iadb_engine                     = "oracle-ee"
  iadb_engine_version             = "19.0.0.0.ru-2024-04.rur-2024-04.r1"
  iadb_username                   = "admin"
  iadb_max_allocated_storage      = "3500"
  iadb_backup_window              = "22:00-01:00"
  iadb_maintenance_window         = "Mon:01:15-Mon:06:00"
  iadb_storage_type               = "gp2"
  appstream_cidr                  = "10.200.32.0/19"
  cidr_ire_workspace              = "10.200.96.0/19"
  workspaces_cidr                 = contains(["development", "testing"], local.environment) ? "10.200.0.0/20" : "10.200.16.0/20"
  cp_vpc_cidr                     = "172.20.0.0/20"
  lzprd-vpc                       = "10.205.0.0/20"

  # CloudWatch Alarms IGDB
  igdb_cpu_threshold                     = "75"
  igdb_cpu_alert_period                  = "60"
  igdb_cpu_evaluation_period             = "5"
  igdb_memory_threshold                  = "500"
  igdb_memory_alert_period               = "60"
  igdb_memory_evaluation_period          = "5"
  igdb_storage_space_threshold           = "50"
  igdb_storage_space_alert_period        = "60"
  igdb_storage_space_evaluation_period   = "5"
  igdb_read_latency_threshold            = "0.5"
  igdb_read_latency_alert_period         = "60"
  igdb_read_latency_evaluation_period    = "5"
  igdb_swap_usage_threshold              = "500000000"
  igdb_swap_usage_alert_period           = "60"
  igdb_swap_usage_evaluation_period      = "5"
  igdb_burst_balance_threshold           = "1"
  igdb_burst_balance_alert_period        = "300"
  igdb_burst_balance_evaluation_period   = "3"
  igdb_write_latency_threshold           = "0.5"
  igdb_write_latency_alert_period        = "60"
  igdb_write_latency_evaluation_period   = "5"
  igdb_read_iops_threshold               = "300"
  igdb_read_iops_alert_period            = "300"
  igdb_read_iops_evaluation_period       = "3"
  igdb_write_iops_threshold              = "300"
  igdb_write_iops_alert_period           = "300"
  igdb_write_iops_evaluation_period      = "3"
  igdb_diskqueue_depth_threshold         = "4"
  igdb_diskqueue_depth_alert_period      = "60"
  igdb_diskqueue_depth_evaluation_period = "5"

  # CloudWatch Alarms IADB
  iadb_cpu_threshold                     = "75"
  iadb_cpu_alert_period                  = "60"
  iadb_cpu_evaluation_period             = "5"
  iadb_memory_threshold                  = "500"
  iadb_memory_alert_period               = "60"
  iadb_memory_evaluation_period          = "5"
  iadb_storage_space_threshold           = "50"
  iadb_storage_space_alert_period        = "60"
  iadb_storage_space_evaluation_period   = "5"
  iadb_read_latency_threshold            = "0.5"
  iadb_read_latency_alert_period         = "60"
  iadb_read_latency_evaluation_period    = "5"
  iadb_swap_usage_threshold              = "500000000"
  iadb_swap_usage_alert_period           = "60"
  iadb_swap_usage_evaluation_period      = "5"
  iadb_burst_balance_threshold           = "1"
  iadb_burst_balance_alert_period        = "300"
  iadb_burst_balance_evaluation_period   = "3"
  iadb_write_latency_threshold           = "0.5"
  iadb_write_latency_alert_period        = "60"
  iadb_write_latency_evaluation_period   = "5"
  iadb_read_iops_threshold               = "300"
  iadb_read_iops_alert_period            = "300"
  iadb_read_iops_evaluation_period       = "3"
  iadb_write_iops_threshold              = "300"
  iadb_write_iops_alert_period           = "300"
  iadb_write_iops_evaluation_period      = "3"
  iadb_diskqueue_depth_threshold         = "4"
  iadb_diskqueue_depth_alert_period      = "60"
  iadb_diskqueue_depth_evaluation_period = "5"
}

resource "aws_db_subnet_group" "igdb" {
  name       = "${local.application_name}-${local.environment}-subnetgrp-${lower(local.igdb_dbname)}"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp-igdb" },
    { "Keep" = "true" }

  )

}

resource "aws_db_subnet_group" "iadb" {
  name       = "${local.application_name}-${local.environment}-subnetgrp-${lower(local.iadb_dbname)}"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp-iadb" },
    { "Keep" = "true" }

  )

}

resource "aws_db_parameter_group" "igdb-parametergroup-19c" {
  name        = "${local.application_name}-${local.environment}-parametergroup-${lower(local.igdb_dbname)}"
  family      = "oracle-ee-19"
  description = "${local.application_name}-${local.environment}-parametergroup-${lower(local.igdb_dbname)}"


  parameter {
    name         = "open_cursors"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "processes"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "query_rewrite_enabled"
    value        = "TRUE"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "query_rewrite_integrity"
    value        = "TRUSTED"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "sessions"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "sqlnetora.sqlnet.allowed_logon_version_server"
    value        = "11"
    apply_method = "pending-reboot"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-parametergroup-igdb" },
    { "Keep" = "true" }
  )
}

resource "aws_db_parameter_group" "iadb-parametergroup-19c" {
  name        = "${local.application_name}-${local.environment}-parametergroup-${lower(local.iadb_dbname)}"
  family      = "oracle-ee-19"
  description = "${local.application_name}-${local.environment}-parametergroup-${lower(local.iadb_dbname)}"


  parameter {
    name         = "open_cursors"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "processes"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "query_rewrite_enabled"
    value        = "TRUE"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "query_rewrite_integrity"
    value        = "TRUSTED"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "sessions"
    value        = "1000"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "sqlnetora.sqlnet.allowed_logon_version_server"
    value        = "11"
    apply_method = "pending-reboot"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-parametergroup-iadb" },
    { "Keep" = "true" }
  )
}

resource "aws_db_option_group" "PortalIGDB19OptionGroup" {
  name                     = "${local.application_name}-${local.environment}-optiongroup-${lower(local.igdb_dbname)}"
  option_group_description = "Portal IGDB DB 19- enables STATSPACK"
  engine_name              = "oracle-ee"
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-optiongroup-igdb" },
    { "Keep" = "true" }
  )
}

resource "aws_db_option_group" "PortalIADB19OptionGroup" {
  name                     = "${local.application_name}-${local.environment}-optiongroup-${lower(local.iadb_dbname)}"
  option_group_description = "Portal IADB DB 19- enables STATSPACK"
  engine_name              = "oracle-ee"
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-optiongroup-iadb" },
    { "Keep" = "true" }
  )
}

resource "aws_security_group" "igdb" {
  name        = "${local.application_name}-${local.environment}-secgroup-DB-${lower(local.igdb_dbname)}"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "AppStream Inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.appstream_cidr]

  }

  ingress {
    description = "SharedServices Inbound - Workspaces etc"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.workspaces_cidr]

  }

  ingress {
    description = "Cloud Platform VPC Internal Traffic inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cp_vpc_cidr]

  }


  ingress {
    description = "Connectivity from MP Environment VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }


  ingress {
    description     = "Inbound TNS access from Portal IDM Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.idm_instance.id]
  }


  ingress {
    description     = "Inbound TNS access from Portal OAM Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.oam_instance.id]
  }


  ingress {
    description     = "Inbound TNS access from Portal OIM Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.oim_instance.id]
  }


  ingress {
    description     = "Inbound TNS access from Portal OHS Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.ohs_instance.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-igdb" }
  )
}

resource "aws_security_group" "iadb" {
  name        = "${local.application_name}-${local.environment}-secgroup-DB-${lower(local.iadb_dbname)}"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "AppStream Inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.appstream_cidr]

  }

  ingress {
    description = "SharedServices Inbound - Workspaces etc"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.workspaces_cidr]

  }

  ingress {
    description = "Cloud Platform VPC Internal Traffic inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cp_vpc_cidr]

  }


  ingress {
    description = "Connectivity from MP Environment VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }


  ingress {
    description     = "Inbound TNS access from Portal IDM Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.idm_instance.id]
  }


  ingress {
    description     = "Inbound TNS access from Portal OAM Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.oam_instance.id]
  }


  ingress {
    description     = "Inbound TNS access from Portal OIM Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.oim_instance.id]
  }


  ingress {
    description     = "Inbound TNS access from Portal OHS Instances"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.ohs_instance.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-iadb" }
  )
}


resource "random_password" "rds_password_igdb" {
  length  = 16
  special = false
}

resource "random_password" "rds_password_iadb" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_password_secret_igdb" {
  name        = "${local.application_name}/app/db-master-password-igdb"
  description = "This secret has a dynamically generated password."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/db-master-password-igdb" },
  )
}

resource "aws_secretsmanager_secret" "rds_password_secret_iadb" {
  name        = "${local.application_name}/app/db-master-password-iadb"
  description = "This secret has a dynamically generated password."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/db-master-password-iadb" },
  )
}

resource "aws_secretsmanager_secret_version" "rds_password_secret_version_igdb" {
  secret_id = aws_secretsmanager_secret.rds_password_secret_igdb.id
  secret_string = jsonencode(
    {
      username = local.igdb_username
      password = random_password.rds_password_igdb.result
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_password_secret_version_iadb" {
  secret_id = aws_secretsmanager_secret.rds_password_secret_iadb.id
  secret_string = jsonencode(
    {
      username = local.iadb_username
      password = random_password.rds_password_iadb.result
    }
  )
}

resource "aws_db_instance" "appdb1" {
  allocated_storage               = local.igdb_storage_size
  db_name                         = local.igdb_dbname
  identifier                      = lower(local.igdb_dbname)
  engine                          = local.igdb_engine
  engine_version                  = local.igdb_engine_version
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  performance_insights_enabled    = true
  instance_class                  = local.igdb_instance_class
  auto_minor_version_upgrade      = local.igdb_auto_minor_version_upgrade
  storage_type                    = local.igdb_storage_type
  backup_retention_period         = local.igdb_backup_retention_period
  backup_window                   = local.igdb_backup_window
  character_set_name              = local.igdb_character_set_name
  #max_allocated_storage           = local.max_allocated_storage
  username               = local.igdb_username
  password               = random_password.rds_password_igdb.result
  vpc_security_group_ids = [aws_security_group.igdb.id]
  #skip_final_snapshot             = false
  final_snapshot_identifier = "${local.application_name}-igdb-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name      = aws_db_parameter_group.igdb-parametergroup-19c.name
  db_subnet_group_name      = aws_db_subnet_group.igdb.name
  maintenance_window        = local.igdb_maintenance_window
  license_model             = "bring-your-own-license"
  #TODO deletion_protection   = true
  copy_tags_to_snapshot = true
  storage_encrypted     = true
  #apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.application_data.accounts[local.environment].igdb_snapshot_name)
  kms_key_id                  = data.aws_kms_key.rds_shared.arn
  publicly_accessible         = false
  allow_major_version_upgrade = true
  multi_az                    = false
  option_group_name           = aws_db_option_group.PortalIGDB19OptionGroup.name

  timeouts {
    create = "60m"
    delete = "2h"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.igdb_dbname}" },
    { "Keep" = "true" },
    { "scheduler:ebs-snapshot" = "True" }
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      final_snapshot_identifier
    ]
  }
}

resource "aws_db_instance" "appdb2" {
  allocated_storage               = local.iadb_storage_size
  db_name                         = local.iadb_dbname
  identifier                      = lower(local.iadb_dbname)
  engine                          = local.iadb_engine
  engine_version                  = local.iadb_engine_version
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  performance_insights_enabled    = true
  instance_class                  = local.iadb_instance_class
  auto_minor_version_upgrade      = local.iadb_auto_minor_version_upgrade
  storage_type                    = local.iadb_storage_type
  backup_retention_period         = local.iadb_backup_retention_period
  backup_window                   = local.iadb_backup_window
  character_set_name              = local.iadb_character_set_name
  #max_allocated_storage           = local.max_allocated_storage
  username               = local.iadb_username
  password               = random_password.rds_password_iadb.result
  vpc_security_group_ids = [aws_security_group.iadb.id]
  #skip_final_snapshot             = false
  final_snapshot_identifier = "${local.application_name}-iadb-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name      = aws_db_parameter_group.iadb-parametergroup-19c.name
  db_subnet_group_name      = aws_db_subnet_group.iadb.name
  maintenance_window        = local.iadb_maintenance_window
  license_model             = "bring-your-own-license"
  #TODO deletion_protection   = true
  copy_tags_to_snapshot = true
  storage_encrypted     = true
  #apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.application_data.accounts[local.environment].iadb_snapshot_name)
  kms_key_id                  = data.aws_kms_key.rds_shared.arn
  publicly_accessible         = false
  allow_major_version_upgrade = true
  multi_az                    = false
  option_group_name           = aws_db_option_group.PortalIADB19OptionGroup.name

  timeouts {
    create = "60m"
    delete = "2h"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.iadb_dbname}" },
    { "Keep" = "true" },
    { "scheduler:ebs-snapshot" = "True" }
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      final_snapshot_identifier
    ]
  }

}

#IGDB alarms
resource "aws_cloudwatch_metric_alarm" "igdb_rds_cpu" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-CPU-utilization"
  alarm_description  = "The average CPU utilization is too high"
  namespace          = "AWS/RDS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = local.igdb_cpu_alert_period
  evaluation_periods = local.igdb_cpu_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_cpu_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-CPU-utilization"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_memory" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-free-memory"
  alarm_description  = "Average RDS memory usage exceeds the predefined threshold"
  namespace          = "AWS/RDS"
  metric_name        = "FreeableMemory"
  statistic          = "Sum"
  period             = local.igdb_memory_alert_period
  evaluation_periods = local.igdb_memory_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_memory_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-free-memory"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_storage-space" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-free-storage-space"
  alarm_description  = "Free Storage Space is Low"
  namespace          = "AWS/RDS"
  metric_name        = "FreeStorageSpace"
  statistic          = "Average"
  period             = local.igdb_storage_space_alert_period
  evaluation_periods = local.igdb_storage_space_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_storage_space_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-free-storage-space"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_read_latency" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-read-latency"
  alarm_description  = "Read Latency Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "ReadLatency"
  statistic          = "Average"
  period             = local.igdb_read_latency_alert_period
  evaluation_periods = local.igdb_read_latency_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_read_latency_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-read-latency"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_swapusage" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-swap-usage"
  alarm_description  = "Swap Usage Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "SwapUsage"
  statistic          = "Sum"
  period             = local.igdb_swap_usage_alert_period
  evaluation_periods = local.igdb_swap_usage_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_swap_usage_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-swap-usage"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_burst_balance" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-burst-balance"
  alarm_description  = "BurstBalance exceeds the threshold"
  namespace          = "AWS/RDS"
  metric_name        = "BurstBalance"
  statistic          = "Sum"
  period             = local.igdb_burst_balance_alert_period
  evaluation_periods = local.igdb_burst_balance_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_burst_balance_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-burst-balance"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_write_latency" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-write-latency"
  alarm_description  = "Write Latency Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "WriteLatency"
  statistic          = "Average"
  period             = local.igdb_write_latency_alert_period
  evaluation_periods = local.igdb_write_latency_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_write_latency_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-write-latency"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_read_iops" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-read-iops"
  alarm_description  = "Read IOPS Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "ReadIOPS"
  statistic          = "Sum"
  period             = local.igdb_read_iops_alert_period
  evaluation_periods = local.igdb_read_iops_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_read_iops_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-read-iops"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_write_iops" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-write-iops"
  alarm_description  = "Write IOPS Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "WriteIOPS"
  statistic          = "Sum"
  period             = local.igdb_write_iops_alert_period
  evaluation_periods = local.igdb_write_iops_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_write_iops_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-write-iops"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "igdb_rds_diskqueue_depth" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-diskqueue-depth"
  alarm_description  = "DiskQueueDepth Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "DiskQueueDepth"
  statistic          = "Average"
  period             = local.igdb_diskqueue_depth_alert_period
  evaluation_periods = local.igdb_diskqueue_depth_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.igdb_diskqueue_depth_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb1.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.igdb_dbname)}-diskqueue-depth"
    }
  )
}

#IADB alarms
resource "aws_cloudwatch_metric_alarm" "iadb_rds_cpu" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-CPU-utilization"
  alarm_description  = "The average CPU utilization is too high"
  namespace          = "AWS/RDS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = local.iadb_cpu_alert_period
  evaluation_periods = local.iadb_cpu_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_cpu_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-CPU-utilization"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_memory" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-free-memory"
  alarm_description  = "Average RDS memory usage exceeds the predefined threshold"
  namespace          = "AWS/RDS"
  metric_name        = "FreeableMemory"
  statistic          = "Sum"
  period             = local.iadb_memory_alert_period
  evaluation_periods = local.iadb_memory_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_memory_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-free-memory"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_storage_space" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-free-storage-space"
  alarm_description  = "Free Storage Space is Low"
  namespace          = "AWS/RDS"
  metric_name        = "FreeStorageSpace"
  statistic          = "Average"
  period             = local.iadb_storage_space_alert_period
  evaluation_periods = local.iadb_storage_space_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_storage_space_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-free-storage-space"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_read_latency" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-read-latency"
  alarm_description  = "Read Latency Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "ReadLatency"
  statistic          = "Average"
  period             = local.iadb_read_latency_alert_period
  evaluation_periods = local.iadb_read_latency_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_read_latency_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-read-latency"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_swapusage" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-swap-usage"
  alarm_description  = "Swap Usage Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "SwapUsage"
  statistic          = "Sum"
  period             = local.iadb_swap_usage_alert_period
  evaluation_periods = local.iadb_swap_usage_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_swap_usage_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-swap-usage"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_burst_balance" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-burst-balance"
  alarm_description  = "BurstBalance exceeds the threshold"
  namespace          = "AWS/RDS"
  metric_name        = "BurstBalance"
  statistic          = "Sum"
  period             = local.iadb_burst_balance_alert_period
  evaluation_periods = local.iadb_burst_balance_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_burst_balance_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "LessThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-burst-balance"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_write_latency" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-write-latency"
  alarm_description  = "Write Latency Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "WriteLatency"
  statistic          = "Average"
  period             = local.iadb_write_latency_alert_period
  evaluation_periods = local.iadb_write_latency_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_write_latency_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-write-latency"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_read_iops" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-read-iops"
  alarm_description  = "Read IOPS Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "ReadIOPS"
  statistic          = "Sum"
  period             = local.iadb_read_iops_alert_period
  evaluation_periods = local.iadb_read_iops_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_read_iops_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-read-iops"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_write_iops" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-write-iops"
  alarm_description  = "Write IOPS Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "WriteIOPS"
  statistic          = "Sum"
  period             = local.iadb_write_iops_alert_period
  evaluation_periods = local.iadb_write_iops_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_write_iops_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-write-iops"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "iadb_rds_diskqueue_depth" {
  alarm_name         = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-diskqueue-depth"
  alarm_description  = "DiskQueueDepth Is Too High"
  namespace          = "AWS/RDS"
  metric_name        = "DiskQueueDepth"
  statistic          = "Average"
  period             = local.iadb_diskqueue_depth_alert_period
  evaluation_periods = local.iadb_diskqueue_depth_evaluation_period
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  threshold          = local.iadb_diskqueue_depth_threshold
  treat_missing_data = "breaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.appdb2.identifier
  }
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-${lower(local.iadb_dbname)}-diskqueue-depth"
    }
  )
}