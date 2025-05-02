#checkov:skip=CKV2_AWS_60: "ignore - Ensure RDS instance with copy tags to snapshots is enabled"
resource "aws_db_instance" "iaps" {
  engine         = "oracle-ee"
  engine_version = local.application_data.accounts[local.environment].db_engine_version
  license_model  = "bring-your-own-license"
  storage_type   = "gp3"
  instance_class = local.application_data.accounts[local.environment].db_instance_class
  db_name        = "IAPS"
  identifier     = "iaps"

  username                      = local.application_data.accounts[local.environment].db_user
  manage_master_user_password   = true
  master_user_secret_kms_key_id = data.aws_kms_key.general_shared.arn
  snapshot_identifier           = length(local.iaps_snapshot_data_refresh_id) > 0 && local.iaps_snapshot_data_refresh_id != "null" ? local.iaps_snapshot_data_refresh_id : null
  db_subnet_group_name          = aws_db_subnet_group.iaps.id
  vpc_security_group_ids        = [aws_security_group.iaps_db.id, aws_security_group.iaps_oem.id]

  # tflint-ignore: aws_db_instance_default_parameter_group
  parameter_group_name  = "default.oracle-ee-19"
  option_group_name      = aws_db_option_group.oracle_oem_agent.name
  ca_cert_identifier    = "rds-ca-rsa2048-g1"
  skip_final_snapshot   = local.application_data.accounts[local.environment].db_skip_final_snapshot
  allocated_storage     = local.application_data.accounts[local.environment].db_allocated_storage
  max_allocated_storage = local.application_data.accounts[local.environment].db_max_allocated_storage
  apply_immediately     = local.application_data.accounts[local.environment].db_apply_immediately
  maintenance_window    = local.application_data.accounts[local.environment].db_maintenance_window
  #checkov:skip=CKV_AWS_226: "minor auto upgrade optional (disabled) for iaps"
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
  kms_key_id        = data.aws_kms_key.rds_shared.arn
  storage_encrypted = true
  #checkov:skip=CKV_AWS_353: "performance insights enabled but optional"
  performance_insights_enabled    = local.application_data.accounts[local.environment].db_performance_insights_enabled
  performance_insights_kms_key_id = "" #tfsec:ignore:aws-rds-enable-performance-insights-encryption Left empty so that it will run, however should be populated with real key in scenario.
  enabled_cloudwatch_logs_exports = local.application_data.accounts[local.environment].db_enabled_cloudwatch_logs_exports

  deletion_protection      = local.is-production ? true : false
  delete_automated_backups = false

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-database", local.application_name, local.environment)) }
  )

  # lifecycle {
  #   ignore_changes = [snapshot_identifier]
  # }
}

resource "aws_ssm_parameter" "iaps_snapshot_data_refresh_id" {
  name        = "/iaps/snapshot_id"
  description = "The ID of the RDS snapshot used for the IAPS database data refresh"
  type        = "String"
  value       = try(local.application_data.accounts[local.environment].db_snapshot_identifier, "")

  tags = {
    environment = "production"
  }

  lifecycle {
    ignore_changes = [value]
  }
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

#checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
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

#checkov:skip=CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
resource "aws_security_group" "iaps_oem" {
  name        = "allow_hmpps_oem"
  description = "Allow DB and OEM Agent traffic to/from HMPPS OEM"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_security_group_rule" "oem_ingress_traffic_vpc" {
  for_each          = local.application_data.oem_sg_ingress_rules_vpc
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps_oem.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "oem_egress_traffic_vpc" {
  for_each          = local.application_data.oem_sg_egress_rules_vpc
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps_oem.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
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

resource "aws_db_option_group" "oracle_oem_agent" {
  name                     = "oracle-oem-option-group"
  option_group_description = "Option group with OEM_AGENT for Oracle RDS"
  engine_name              = "oracle-ee"
  major_engine_version     = local.application_data.accounts[local.environment].major_engine_version

  option {
    option_name = "OEM_AGENT"

    option_settings {
      name  = "AGENT_VERSION"
      value = local.application_data.accounts[local.environment].oem_agent_version
    }
    option_settings {
      name  = "AGENT_PORT"
      value = local.application_data.accounts[local.environment].oem_agent_port
    }
    option_settings {
      name  = "OEM_HOST"
      value = local.application_data.accounts[local.environment].oem_host
    }
    option_settings {
      name  = "OEM_PORT"
      value = local.application_data.accounts[local.environment].oem_port
    }
    option_settings {
      name  = "AGENT_REGISTRATION_PASSWORD"
      value = local.oem_agent_password
    }
    vpc_security_group_memberships = [
      aws_security_group.iaps_oem.id
    ]
  }

  tags = local.tags
}
