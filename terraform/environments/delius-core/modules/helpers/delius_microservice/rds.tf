resource "random_id" "rds_suffix" {
  keepers = {
    snapshot_id = var.snapshot_identifier
  }

  byte_length = 2
}

resource "aws_security_group" "db" {
  count       = var.create_rds ? 1 : 0
  name        = "${var.name}-${var.env_name}-rds-security-group"
  description = "controls access to db"
  vpc_id      = var.account_config.shared_vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.env_name}-db_security_group"
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_custom" {
  for_each = {
    for sg in var.db_ingress_security_groups : sg => sg
  }
  security_group_id            = aws_security_group.db[0].id
  from_port                    = var.rds_port
  to_port                      = var.rds_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
  description                  = "Allow RDS traffic from ${each.value}"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_bastion" {
  count                        = var.create_rds ? 1 : 0
  security_group_id            = aws_security_group.db[0].id
  from_port                    = var.rds_port
  to_port                      = var.rds_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.bastion_sg_id
  description                  = "Allow RDS traffic from service"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_service" {
  count                        = var.create_rds ? 1 : 0
  security_group_id            = aws_security_group.db[0].id
  from_port                    = var.rds_port
  to_port                      = var.rds_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service.id
  description                  = "Allow RDS traffic from service"
}

resource "aws_db_subnet_group" "this" {
  count      = var.create_rds ? 1 : 0
  name       = "${var.env_name}-${var.name}-data-tier"
  subnet_ids = var.account_config.ordered_private_subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  count          = var.create_rds ? 1 : 0
  engine         = var.rds_engine
  license_model  = var.rds_license_model != null ? var.rds_license_model : null
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class
  identifier     = "${var.name}-${var.env_name}-db"
  username       = var.rds_username

  manage_master_user_password = true

  snapshot_identifier = var.snapshot_identifier != null ? var.snapshot_identifier : null

  kms_key_id = var.account_config.kms_keys.rds_shared

  allow_major_version_upgrade = var.rds_allow_major_version_upgrade
  apply_immediately           = var.rds_apply_immediately

  # tflint-ignore: aws_db_instance_default_parameter_group
  parameter_group_name                = var.rds_parameter_group_name
  deletion_protection                 = var.rds_deletion_protection
  delete_automated_backups            = var.rds_delete_automated_backups
  skip_final_snapshot                 = var.rds_skip_final_snapshot
  final_snapshot_identifier           = !var.rds_skip_final_snapshot ? "${var.name}-${var.env_name}-db-final-${random_id.rds_suffix.hex}" : null
  allocated_storage                   = var.rds_allocated_storage
  max_allocated_storage               = var.rds_max_allocated_storage
  storage_type                        = var.rds_storage_type
  maintenance_window                  = var.maintenance_window
  auto_minor_version_upgrade          = true
  backup_window                       = var.rds_backup_window
  backup_retention_period             = var.rds_backup_retention_period
  iam_database_authentication_enabled = var.rds_iam_database_authentication_enabled
  db_subnet_group_name                = aws_db_subnet_group.this[0].id
  vpc_security_group_ids              = [aws_security_group.db[0].id]
  multi_az                            = var.rds_multi_az
  monitoring_interval                 = var.rds_monitoring_interval
  monitoring_role_arn                 = var.rds_monitoring_interval != null || var.rds_monitoring_interval != 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  #checkov:skip=CKV_AWS_118: "enhanced monitoring is enabled, but optional"
  storage_encrypted               = true
  performance_insights_enabled    = var.rds_performance_insights_enabled
  performance_insights_kms_key_id = var.rds_performance_insights_enabled ? var.account_config.kms_keys.general_shared : null
  enabled_cloudwatch_logs_exports = var.rds_enabled_cloudwatch_logs_exports
  tags = merge(var.tags,
    { Name = lower(format("%s-%s-database", var.name, var.env_name)) },
    var.enable_platform_backups != null ? { "backup" = var.enable_platform_backups ? "true" : "false" } : {}
  )
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring[0].json
  count              = var.rds_monitoring_interval != null || var.rds_monitoring_interval != 0 ? 1 : 0
  name_prefix        = "rds-enhanced-monitoring"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.create_rds ? 1 : (var.rds_monitoring_interval != null || var.rds_monitoring_interval != 0 ? 1 : 0)
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  count = var.create_rds ? 1 : (var.rds_monitoring_interval != null || var.rds_monitoring_interval != 0 ? 1 : 0)
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}
