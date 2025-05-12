resource "aws_db_subnet_group" "igdb" {
  name       = "${local.application_name}-${local.environment}-subnetgrp-igdb"
  subnet_ids = [module.vpc.database_subnets.0, module.vpc.database_subnets.1, module.vpc.database_subnets.2]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp-igdb" },
    { "Keep" = "true" }

  )

}

resource "aws_db_subnet_group" "iadb" {
  name       = "${local.application_name}-${local.environment}-subnetgrp-iadb"
  subnet_ids = [module.vpc.database_subnets.0, module.vpc.database_subnets.1, module.vpc.database_subnets.2]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp-iadb" },
    { "Keep" = "true" }

  )

}

resource "aws_db_parameter_group" "igdb19" {
  name        = "${local.application_name}-${local.environment}-parametergroup-igdb"
  family      = "oracle-ee-19"
  description = "${local.application_name}-${local.environment}-parametergroup-igdb"


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

resource "aws_db_parameter_group" "iadb19" {
  name        = "${local.application_name}-${local.environment}-parametergroup-iadb"
  family      = "oracle-ee-19"
  description = "${local.application_name}-${local.environment}-parametergroup-iadb"


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

resource "aws_db_option_group" "igdb19" {
  name                     = "${local.application_name}-${local.environment}-optiongroup-igdb"
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

resource "aws_db_option_group" "iadb19" {
  name                     = "${local.application_name}-${local.environment}-optiongroup-iadb"
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
  name        = "${local.application_name}-${local.environment}-sg-igdb"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-sg-igdb" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "igdb_portal_ec2" {
  for_each = toset(local.portal_ec2_security_group_ids)
  security_group_id = aws_security_group.igdb.id
  description       = "IGDB Inbound from Portal EC2"
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "igdb_portal_ec2" {
  for_each = toset(local.portal_ec2_security_group_ids)
  security_group_id        = aws_security_group.igdb.id
  ip_protocol       = "-1"
  referenced_security_group_id = each.value
}

resource "aws_security_group" "iadb" {
  name        = "${local.application_name}-${local.environment}-sg-iadb"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-sg-iadb" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "iadb_portal_ec2" {
  for_each = toset(local.portal_ec2_security_group_ids)
  security_group_id = aws_security_group.iadb.id
  description       = "IADB Inbound from Portal EC2"
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "iadb_portal_ec2" {
  for_each = toset(local.portal_ec2_security_group_ids)
  security_group_id        = aws_security_group.iadb.id
  ip_protocol       = "-1"
  referenced_security_group_id = each.value
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

resource "aws_db_instance" "igdb" {
  allocated_storage               = "200"
  db_name                         = "IGDB"
  identifier                      = "igdb"
  engine                          = "oracle-ee"
  engine_version                  = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  performance_insights_enabled    = true
  instance_class                  = "db.m5.2xlarge"
  auto_minor_version_upgrade      = false
  storage_type                    = "gp2"
  backup_retention_period         = "35"
  backup_window                   = "22:00-01:00"
  character_set_name              = "AL32UTF8"
  #max_allocated_storage           = "3500"
  username               = local.igdb_username
  password               = random_password.rds_password_igdb.result
  vpc_security_group_ids = [aws_security_group.igdb.id]
  #skip_final_snapshot             = false
  final_snapshot_identifier = "${local.application_name}-igdb-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name      = aws_db_parameter_group.igdb19.name
  db_subnet_group_name      = aws_db_subnet_group.igdb.name
  maintenance_window        = "Mon:01:15-Mon:06:00"
  license_model             = "bring-your-own-license"
  #TODO deletion_protection   = true
  copy_tags_to_snapshot = true
  storage_encrypted     = true
  #apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.application_data.accounts[local.environment].igdb_snapshot_name)
  kms_key_id                  = data.aws_kms_key.aws_rds.arn
  publicly_accessible         = false
  allow_major_version_upgrade = true
  multi_az                    = true
  option_group_name           = aws_db_option_group.igdb19.name

  timeouts {
    create = "60m"
    delete = "2h"
  }

  tags = merge(
    local.tags,
    { "Name" = "IGDB" },
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

resource "aws_db_instance" "iadb" {
  allocated_storage               = "200"
  db_name                         = "IADB"
  identifier                      = "iadb"
  engine                          = "oracle-ee"
  engine_version                  = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  performance_insights_enabled    = true
  instance_class                  = "db.m5.2xlarge"
  auto_minor_version_upgrade      = false
  storage_type                    = "gp2"
  backup_retention_period         = "35"
  backup_window                   = "22:00-01:00"
  character_set_name              = "AL32UTF8"
  #max_allocated_storage           = local.max_allocated_storage
  username               = local.iadb_username
  password               = random_password.rds_password_iadb.result
  vpc_security_group_ids = [aws_security_group.iadb.id]
  #skip_final_snapshot             = false
  final_snapshot_identifier = "${local.application_name}-iadb-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name      = aws_db_parameter_group.iadb19.name
  db_subnet_group_name      = aws_db_subnet_group.iadb.name
  maintenance_window        = "mon:01:15-mon:06:00"
  license_model             = "bring-your-own-license"
  #TODO deletion_protection   = true
  copy_tags_to_snapshot = true
  storage_encrypted     = true
  #apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.application_data.accounts[local.environment].iadb_snapshot_name)
  kms_key_id                  = data.aws_kms_key.aws_rds.arn
  publicly_accessible         = false
  allow_major_version_upgrade = true
  multi_az                    = true
  option_group_name           = aws_db_option_group.iadb19.name

  timeouts {
    create = "60m"
    delete = "2h"
  }

  tags = merge(
    local.tags,
    { "Name" = "IADB" },
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