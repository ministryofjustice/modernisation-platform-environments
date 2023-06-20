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
  igdb_engine_version             = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  igdb_username                   = "admin"
  igdb_max_allocated_storage      = "3500"
  igdb_backup_window              = "22:00-01:00"
  igdb_maintenance_window         = "Mon:01:15-Mon:06:00"
  igdb_storage_type               = "gp2"
  igdb_snapshot_name              = "portal-igdb-spike-manual-mp-31052023"
  igdb_snapshot_arn               = "arn:aws:rds:eu-west-2:${data.aws_caller_identity.current.account_id}:snapshot:${local.application_data.accounts[local.environment].igdb_snapshot_name}"
  iadb_dbname                     = "IADB"
  iadb_storage_size               = "200"
  iadb_auto_minor_version_upgrade = false
  iadb_backup_retention_period    = "35"
  iadb_character_set_name         = "AL32UTF8"
  iadb_instance_class             = "db.t3.large"
  iadb_engine                     = "oracle-ee"
  iadb_engine_version             = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  iadb_username                   = "admin"
  iadb_max_allocated_storage      = "3500"
  iadb_backup_window              = "22:00-01:00"
  iadb_maintenance_window         = "Mon:01:15-Mon:06:00"
  iadb_storage_type               = "gp2"
  iadb_snapshot_name              = "portal-iadb-spike-manual-mp-07062023"
  iadb_snapshot_arn               = "arn:aws:rds:eu-west-2:${data.aws_caller_identity.current.account_id}:snapshot:${local.application_data.accounts[local.environment].iadb_snapshot_name}"
  appstream_cidr                  = "10.200.32.0/19"
  cidr_ire_workspace              = "10.200.96.0/19"
  workspaces_cidr                 = "10.200.16.0/20"
  cp_vpc_cidr                     = "172.20.0.0/20"
  lzprd-vpc                       = "10.205.0.0/20"
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
    description = "Ireland Shared Services Inbound - Workspaces etc"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidr_ire_workspace]

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
    description = "Ireland Shared Services Inbound - Workspaces etc"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidr_ire_workspace]

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
  final_snapshot_identifier = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name      = aws_db_parameter_group.igdb-parametergroup-19c.name
  db_subnet_group_name      = aws_db_subnet_group.igdb.name
  maintenance_window        = local.igdb_maintenance_window
  license_model             = "bring-your-own-license"
  #TODO deletion_protection   = true
  copy_tags_to_snapshot = true
  storage_encrypted     = true
  #apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.igdb_snapshot_name)
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
  final_snapshot_identifier = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name      = aws_db_parameter_group.iadb-parametergroup-19c.name
  db_subnet_group_name      = aws_db_subnet_group.iadb.name
  maintenance_window        = local.iadb_maintenance_window
  license_model             = "bring-your-own-license"
  #TODO deletion_protection   = true
  copy_tags_to_snapshot = true
  storage_encrypted     = true
  #apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.iadb_snapshot_name)
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

}

#TODO add correct entry for DNS
# resource "aws_route53_record" "igdb_rds" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
#   type     = "CNAME"
#   ttl      = 60
#   records  = [aws_db_instance.appdb1.address]
# }

#TODO add correct entry for DNS
# resource "aws_route53_record" "iadb_rds" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
#   type     = "CNAME"
#   ttl      = 60
#   records  = [aws_db_instance.appdb2.address]
# }
