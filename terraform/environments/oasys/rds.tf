# should turn into a module
resource "aws_db_instance" "oasys" {
  count          = local.environment_config.db_enabled ? 1 : 0
  engine         = "oracle-ee"
  engine_version = "19.0.0.0.ru-2022-10.rur-2022-10.r1"
  license_model  = "bring-your-own-license"
  instance_class = local.environment_config.db_instance_class
  db_name        = "OASDB"
  identifier     = "${local.application_name}-${local.environment}-database"
  username       = local.environment_config.db_user
  password       = random_password.db_password.result
  # tflint-ignore: aws_db_instance_default_parameter_group
  parameter_group_name  = aws_db_parameter_group.oasys_parameter.name
  character_set_name    = "WE8MSWIN1252"
  skip_final_snapshot   = local.environment_config.db_skip_final_snapshot
  allocated_storage     = local.environment_config.db_allocated_storage
  max_allocated_storage = local.environment_config.db_max_allocated_storage
  maintenance_window    = local.environment_config.db_maintenance_window
  #checkov:skip=CKV_AWS_226: "This is a variable set for each environment"
  auto_minor_version_upgrade  = local.environment_config.db_auto_minor_version_upgrade
  allow_major_version_upgrade = local.environment_config.db_allow_major_version_upgrade
  backup_window               = local.environment_config.db_backup_window
  backup_retention_period     = local.environment_config.db_retention_period
  #checkov:skip=CKV_AWS_133: "backup_retention enabled, can be edited it application_variables.json"
  iam_database_authentication_enabled = local.environment_config.db_iam_database_authentication_enabled
  #checkov:skip=CKV_AWS_161: "iam auth enabled, but optional"
  multi_az = local.environment_config.db_multi_az
  #checkov:skip=CKV_AWS_157: "multi-az enabled, but optional"
  monitoring_interval = local.environment_config.db_monitoring_interval
  monitoring_role_arn = local.environment_config.db_monitoring_interval == 0 ? "" : aws_iam_role.rds_enhanced_monitoring[0].arn
  #checkov:skip=CKV_AWS_118: "enhanced monitoring is enabled, but optional"
  storage_encrypted               = true
  performance_insights_enabled    = local.environment_config.db_performance_insights_enabled
  performance_insights_kms_key_id = "" #tfsec:ignore:aws-rds-enable-performance-insights-encryption Left empty so that it will run, however should be populated with real key in scenario.
  enabled_cloudwatch_logs_exports = local.environment_config.db_enabled_cloudwatch_logs_exports
  db_subnet_group_name            = aws_db_subnet_group.oasys.name
  vpc_security_group_ids          = [aws_security_group.oasys.id]
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database", local.application_name, local.environment)) }
  )
}

resource "aws_db_parameter_group" "oasys_parameter" {
  name   = "oasys_parameters_19c"
  family = "oracle19c"

  parameter {
    name  = "nls_language"
    value = "ENGLISH"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "oasys" {
  name       = "${local.application_name}-${local.environment}-database-subnet-group"
  subnet_ids = data.aws_subnets.shared-data.ids
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database-subnet-group", local.application_name, local.environment)) }
  )

}

resource "aws_security_group" "oasys" {
  name        = "${local.application_name}-${local.environment}-database-security-group"
  description = "Security group for ${local.application_name} ${local.environment} database"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database-security-group", local.application_name, local.environment)) }
  )
  ingress {
    description = "Allow access from live and test environments"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidrs.noms_live, data.aws_vpc.shared.cidr_block, local.cidrs.noms_test]
  }
  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring[0].json
  count              = local.environment_config.db_monitoring_interval == 0 ? 0 : 1
  name_prefix        = "rds-enhanced-monitoring"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = local.environment_config.db_monitoring_interval == 0 ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  count = local.environment_config.db_monitoring_interval == 0 ? 0 : 1

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
