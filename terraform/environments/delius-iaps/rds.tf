# Temporary tf resource to speed up migration
# to be deleted once prod migration is completed
resource "aws_db_snapshot_copy" "local" {
  for_each                      = var.rds_refresh_snapshot_id != "" ? toset([var.rds_refresh_snapshot_id]) : []
  source_db_snapshot_identifier = each.value
  kms_key_id                    = data.aws_kms_key.rds_shared.id
  target_db_snapshot_identifier = "data-refresh-snapshot"
}

resource "aws_db_instance" "iaps" {
  engine         = "oracle-ee"
  engine_version = "19"
  license_model  = "bring-your-own-license"
  instance_class = local.application_data.accounts[local.environment].db_instance_class
  db_name        = "IAPS"
  identifier     = "${local.application_name}-${local.environment}-database"
  username       = local.application_data.accounts[local.environment].db_user
  password       = aws_secretsmanager_secret_version.db_password.secret_string

  # temporary 2-layer try function, to conditionally allow a build from a snapshot originating in an external account
  snapshot_identifier = try(local.application_data.accounts[local.environment].db_snapshot_identifier, try(aws_db_snapshot_copy.local[0].id, null))
  db_subnet_group_name   = aws_db_subnet_group.iaps.id
  vpc_security_group_ids = [aws_security_group.iaps_db.id]

  # tflint-ignore: aws_db_instance_default_parameter_group
  parameter_group_name        = "default.oracle-ee-19"
  skip_final_snapshot         = local.application_data.accounts[local.environment].db_skip_final_snapshot
  allocated_storage           = local.application_data.accounts[local.environment].db_allocated_storage
  max_allocated_storage       = local.application_data.accounts[local.environment].db_max_allocated_storage
  apply_immediately           = local.application_data.accounts[local.environment].db_apply_immediately
  maintenance_window          = local.application_data.accounts[local.environment].db_maintenance_window
  auto_minor_version_upgrade  = local.application_data.accounts[local.environment].db_auto_minor_version_upgrade
  allow_major_version_upgrade = local.application_data.accounts[local.environment].db_allow_major_version_upgrade
  backup_window               = local.application_data.accounts[local.environment].db_backup_window
  backup_retention_period     = local.application_data.accounts[local.environment].db_backup_retention_period
  #checkov:skip=CKV_AWS_133: "backup_retention enabled, can be edited it application_variables.json"
  iam_database_authentication_enabled = local.application_data.accounts[local.environment].db_iam_database_authentication_enabled
  #checkov:skip=CKV_AWS_161: "iam auth enabled, but optional"
  multi_az = local.application_data.accounts[local.environment].db_multi_az
  #checkov:skip=CKV_AWS_157: "multi-az enabled, but optional"
  monitoring_interval = local.application_data.accounts[local.environment].db_monitoring_interval
  monitoring_role_arn = local.application_data.accounts[local.environment].db_monitoring_interval == 0 ? "" : aws_iam_role.rds_enhanced_monitoring[0].arn
  #checkov:skip=CKV_AWS_118: "enhanced monitoring is enabled, but optional"
  storage_encrypted               = true
  performance_insights_enabled    = local.application_data.accounts[local.environment].db_performance_insights_enabled
  performance_insights_kms_key_id = "" #tfsec:ignore:aws-rds-enable-performance-insights-encryption Left empty so that it will run, however should be populated with real key in scenario.
  enabled_cloudwatch_logs_exports = local.application_data.accounts[local.environment].db_enabled_cloudwatch_logs_exports

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database", local.application_name, local.environment)) }
  )
}

resource "aws_db_subnet_group" "iaps" {
  name = "iaps_data_subnets"
  subnet_ids = [
    data.aws_subnet.data_subnets_a.id,
    data.aws_subnet.data_subnets_b.id,
    data.aws_subnet.data_subnets_c.id
  ]

  tags = local.tags
}

resource "aws_security_group" "iaps_db" {
  name        = "allow_iaps_vm"
  description = "Allow DB traffic from IAPS VM"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_db_in" {
  security_group_id = aws_security_group.iaps_db.id

  referenced_security_group_id = aws_security_group.iaps.id
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring[0].json
  count              = local.application_data.accounts[local.environment].db_monitoring_interval == 0 ? 0 : 1
  name_prefix        = "rds-enhanced-monitoring"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = local.application_data.accounts[local.environment].db_monitoring_interval == 0 ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  count = local.application_data.accounts[local.environment].db_monitoring_interval == 0 ? 0 : 1

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
