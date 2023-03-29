#------------------------------------------------------------------------------
# RDS DB Instance
#------------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine            = var.instance.engine
  engine_version    = var.instance.engine_version
  instance_class    = var.instance.instance_class
  allocated_storage = var.instance.allocated_storage
  storage_type      = var.instance.storage_type
  storage_encrypted = var.instance.storage_encrypted
  kms_key_id        = var.instance.kms_key_id
  license_model     = var.instance.license_model

  db_name                             = var.instance.db_name
  username                            = var.instance.username
  password                            = aws_ssm_parameter.db_password.value
  port                                = var.instance.port
  iam_database_authentication_enabled = var.instance.iam_database_authentication_enabled

  replicate_source_db = var.instance.replicate_source_db

  snapshot_identifier = var.instance.snapshot_identifier

  vpc_security_group_ids = var.instance.vpc_security_group_ids
  db_subnet_group_name   = var.instance.db_subnet_group_name
  parameter_group_name   = var.instance.parameter_group_name
  option_group_name      = var.instance.option_group_name

  availability_zone   = var.availability_zone
  multi_az            = var.instance.multi_az
  iops                = var.instance.iops
  publicly_accessible = var.instance.publicly_accessible
  monitoring_interval = var.instance.monitoring_interval
  monitoring_role_arn = var.instance.monitoring_role_arn

  allow_major_version_upgrade = var.instance.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.instance.auto_minor_version_upgrade
  apply_immediately           = var.instance.apply_immediately
  maintenance_window          = var.instance.maintenance_window
  skip_final_snapshot         = var.instance.skip_final_snapshot
  copy_tags_to_snapshot       = var.instance.copy_tags_to_snapshot
  final_snapshot_identifier   = var.instance.final_snapshot_identifier

  backup_retention_period = var.instance.backup_retention_period
  backup_window           = var.instance.backup_window

  character_set_name = var.instance.character_set_name

  tags = merge(local.tags, {
    Name = var.identifier
  })

  enabled_cloudwatch_logs_exports = var.instance.enabled_cloudwatch_logs_exports
}

resource "aws_db_instance_automated_backups_replication" "this" {
  source_db_instance_arn = aws_db_instance.this.arn
  retention_period       = var.instance_automated_backups_replication
}

#-------------------------------------------------------------
## Getting the rds db password
#-------------------------------------------------------------
resource "random_password" "rds_admin_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.ssm_parameters_prefix}${var.identifier}/rds_admin_password"
  description = "RDS Admin Password"
  type        = "SecureString"
  value       = random_password.rds_admin_password.result
}

#------------------------------------------------------------------------------
# OPTION GROUPS
#------------------------------------------------------------------------------

resource "aws_db_option_group" "this" {
  count = var.option_group.create ? 1 : 0

  name_prefix              = var.option_group.name_prefix != null ? var.option_group.name_prefix : var.identifier
  option_group_description = var.option_group.option_group_description != null ? var.option_group.option_group_description : "Database option group for ${var.identifier}"
  engine_name              = var.option_group.engine_name
  major_engine_version     = var.option_group.major_engine_version
  dynamic "option" {
    for_each = var.option_group.options
    content {
      option_name                    = option.value.option_name
      port                           = option.value.port
      version                        = option.value.version
      db_security_group_memberships  = option.value.db_security_group_memberships
      vpc_security_group_memberships = option.value.vpc_security_group_memberships
      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }
  tags = merge(local.tags, {
    Name = var.option_group.name_prefix
  })
}

#------------------------------------------------------------------------------
# PARAMETER GROUPS
#------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  count = var.parameter_group.create ? 1 : 0

  name_prefix = var.parameter_group.name_prefix != null ? var.parameter_group.name_prefix : var.identifier
  description = var.parameter_group.description != null ? var.parameter_group.description : "Database parameter group for ${var.identifier}"
  family      = var.parameter_group.family

  dynamic "parameter" {
    for_each = var.parameter_group.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
  tags = merge(local.tags, {
    Name = var.parameter_group.name_prefix
  })

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# SUBNET GROUPS
#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  count = var.subnet_group.create ? 1 : 0

  name_prefix = var.subnet_group.name_prefix != null ? var.subnet_group.name_prefix : var.identifier
  description = var.subnet_group.description != null ? var.subnet_group.descriptio : "Database subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_group.subnet_ids

  tags = merge(local.tags, {
    Name = var.subnet_group.name_prefix
  })
}

#------------------------------------------------------------------------------
# IAM
#------------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                 = "${var.iam_resource_names_prefix}-role-${var.identifier}"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "rds.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )

  managed_policy_arns = var.instance_profile_policies

  tags = merge(
    local.tags,
    {
      Name = "${var.iam_resource_names_prefix}-role-${var.identifier}"
    },
  )
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "rds_dns_entry" {
  count    = var.route53_record ? 1 : 0
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.rds_dns_entry.zone_id
  name    = "${var.identifier}.${var.application_name}.${data.aws_route53_zone.rds_dns_entry.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.this.address]
}