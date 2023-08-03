##
# RDS-related resources
##
# The creation of RDS-related resources is dependent on local.application_data.accounts[local.environment].rds_create
# Context: work was done to experiment with RDS in dev as a suitable backend (nit-593)
# At the time of writing, EC2 seems more viable for a a realistically, completable migration.
# Leaving this code here at this time, with a create switch that can be used to bring the rds instance if need be
# Note, the RDS will be created from the manual snapshot created before the RDS instance was removed.
# Remove this switch and ALL things RDS when this is definitely no longer needed.

##
# Networking pre-reqs
##
resource "aws_security_group" "rds_security_group" {
  count       = local.application_data.accounts[local.environment].rds_create == "true" ? 1 : 0
  name        = "${local.application_name}-rds-database-security-group"
  description = "controls access to rds db instance"
  vpc_id      = data.aws_vpc.shared.id

  # Allow ingress from front end SG 
  ingress {
    protocol    = "tcp"
    description = "Allow Oracle traffic"
    from_port   = local.db_port
    to_port     = local.db_port
    security_groups = [
      aws_security_group.delius_core_frontend_security_group.id,
      module.bastion_linux.bastion_security_group
      # Placeholder for security group associated with DMS RI as part of migration PoC
      # Placeholder for security group associated with Source DB as part of migration PoC, e.g. from ECS testing DB SG
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-database-security-group"
    }
  )
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  count      = local.application_data.accounts[local.environment].rds_create == "true" ? 1 : 0
  name       = "data-subnet-set"
  subnet_ids = data.aws_subnets.shared-data.ids
  tags       = local.tags
}

##
# Secret related pre-reqs
##
resource "random_password" "rds_admin_password" {
  count   = local.application_data.accounts[local.environment].rds_create == "true" ? 1 : 0
  length  = 30
  lower   = true
  upper   = true
  special = false
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "rds_admin_password" {
  #checkov:skip=CKV_AWS_149
  count                   = local.application_data.accounts[local.environment].rds_create == "true" ? 1 : 0
  name                    = "${var.networking[0].application}-rds-admin-password"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-rds-admin-password"
    },
  )
}

resource "aws_secretsmanager_secret_version" "rds_admin_password" {
  count         = local.application_data.accounts[local.environment].rds_create == "true" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rds_admin_password[0].id
  secret_string = random_password.rds_admin_password[0].result
}

##
# RDS-related pre-reqs
##
# Always create - do not depend on local.application_data.accounts[local.environment].rds_create due to existing rds snapshot dependencies
resource "aws_db_parameter_group" "rds_parameter_group" {
  name   = format("%s-rds-parameter-group", local.application_name)
  family = format("%s-%s", local.application_data.accounts[local.environment].rds_engine, local.application_data.accounts[local.environment].rds_engine_major_version)
}

# Always create - do not depend on local.application_data.accounts[local.environment].rds_create due to existing rds snapshot dependencies
resource "aws_db_option_group" "rds_option_group" {
  name                     = format("%s-rds-option-group", local.application_name)
  option_group_description = format("%s-rds-option-group", local.application_name)
  engine_name              = local.application_data.accounts[local.environment].rds_engine
  major_engine_version     = local.application_data.accounts[local.environment].rds_engine_major_version
  option {
    option_name = "JVM" # Options needed for full environment include OEM_AGENT and STATSPACK but not added at this PoC point yet.
  }

}

##
# RDS instance
##
resource "aws_db_instance" "delius-core" {
  count                       = local.application_data.accounts[local.environment].rds_create == "true" ? 1 : 0
  engine                      = local.application_data.accounts[local.environment].rds_engine
  license_model               = "bring-your-own-license"
  engine_version              = format("%s.%s", local.application_data.accounts[local.environment].rds_engine_major_version, local.application_data.accounts[local.environment].rds_engine_minor_version)
  instance_class              = local.application_data.accounts[local.environment].rds_instance_class
  identifier                  = format("%s-%s-database", local.application_name, local.environment)
  db_name                     = local.application_data.accounts[local.environment].rds_db_name
  username                    = local.application_data.accounts[local.environment].rds_user
  password                    = aws_secretsmanager_secret_version.rds_admin_password[0].secret_string
  parameter_group_name        = aws_db_parameter_group.rds_parameter_group.name
  option_group_name           = aws_db_option_group.rds_option_group.name
  deletion_protection         = false # This is just a poc
  apply_immediately           = local.application_data.accounts[local.environment].rds_apply_immediately
  skip_final_snapshot         = true
  snapshot_identifier         = "delius-core-development-database-after-nit593-datapump"
  allocated_storage           = local.application_data.accounts[local.environment].rds_allocated_storage
  max_allocated_storage       = local.application_data.accounts[local.environment].rds_max_allocated_storage
  maintenance_window          = local.application_data.accounts[local.environment].rds_maintenance_window
  auto_minor_version_upgrade  = local.application_data.accounts[local.environment].rds_auto_minor_version_upgrade
  allow_major_version_upgrade = local.application_data.accounts[local.environment].rds_allow_major_version_upgrade
  backup_window               = local.application_data.accounts[local.environment].rds_backup_window
  backup_retention_period     = local.application_data.accounts[local.environment].rds_retention_period
  #checkov:skip=CKV_AWS_133: "backup_retention enabled, can be edited it application_variables.json"
  iam_database_authentication_enabled = local.application_data.accounts[local.environment].rds_iam_database_authentication_enabled
  #checkov:skip=CKV_AWS_161: "iam auth enabled, but optional"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group[0].id
  vpc_security_group_ids = [aws_security_group.rds_security_group[0].id]
  multi_az               = local.application_data.accounts[local.environment].rds_multi_az
  #checkov:skip=CKV_AWS_157: "multi-az enabled, but optional"
  monitoring_interval = local.application_data.accounts[local.environment].rds_monitoring_interval
  monitoring_role_arn = local.application_data.accounts[local.environment].rds_monitoring_interval == "0" ? "" : aws_iam_role.rds_enhanced_monitoring[0].arn
  #checkov:skip=CKV_AWS_118: "enhanced monitoring is enabled, but optional"
  storage_encrypted               = true
  performance_insights_enabled    = local.application_data.accounts[local.environment].rds_performance_insights_enabled
  performance_insights_kms_key_id = "" #tfsec:ignore:aws-rds-enable-performance-insights-encryption Left empty so that it will run, however should be populated with real key in scenario.
  enabled_cloudwatch_logs_exports = local.application_data.accounts[local.environment].rds_enabled_cloudwatch_logs_exports
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count              = local.application_data.accounts[local.environment].rds_monitoring_interval == "0" ? 0 : 1
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring[0].json
  name_prefix        = "rds-enhanced-monitoring"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = local.application_data.accounts[local.environment].rds_monitoring_interval == "0" ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  count = local.application_data.accounts[local.environment].rds_monitoring_interval == "0" ? 0 : 1

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
