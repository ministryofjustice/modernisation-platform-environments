resource "aws_db_subnet_group" "igdb" {
  name       = "${local.application_name}-${local.environment}-subnetgrp"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp" },
    { "Keep" = "true" }

  )

}

resource "aws_db_parameter_group" "igdb-parametergroup-19c" {
  name        = "${local.application_name}-${local.environment}-parametergroup"
  family      = "oracle-ee-19"
  description = "${local.application_name}-${local.environment}-parametergroup"


  parameter {
    name  = "open_cursors"
    value = "1000"
  }

  parameter {
    name  = "processes"
    value = "1000"
  }

  parameter {
    name  = "query_rewrite_enabled"
    value = "TRUE"
  }

  parameter {
    name  = "query_rewrite_integrity"
    value = "TRUSTED"
  }

  parameter {
    name  = "sessions"
    value = "1000"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "11"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-parametergroup" },
    { "Keep" = "true" }
  )
}

resource "aws_db_option_group" "PortalIGDB19OptionGroup" {
  name                     = "${local.application_name}-${local.environment}-optiongroup"
  option_group_description = "Portal IGDB DB 19- enables STATSPACK"
  engine_name              = "oracle-ee"
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-optiongroup" },
    { "Keep" = "true" }
  )
}

resource "aws_security_group" "igdb" {
  name        = "${local.application_name}-${local.environment}-secgroup"
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
    description = "Connectivity from Portal IDM VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block_IDM]
  }


  ingress {
    description = "Connectivity from Portal OAM VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block_OAM]
  }


  ingress {
    description = "Connectivity from Portal OIM VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block_OIM]
  }


  ingress {
    description = "Connectivity from Portal OIM VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block_OHS]
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



resource "random_password" "rds_password" {
  length  = 16
  special = false
}


resource "aws_secretsmanager_secret" "rds_password_secret" {
  name        = "${local.application_name}/app/db-master-password"
  description = "This secret has a dynamically generated password."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/db-master-password" },
  )
}


resource "aws_secretsmanager_secret_version" "rds_password_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_password_secret.id
  secret_string = jsonencode(
    {
      username = local.username
      password = random_password.rds_password.result
    }
  )
}



resource "aws_db_instance" "appdb1" {
  allocated_storage               = local.storage_size
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
  #?max_allocated_storage           = local.max_allocated_storage
  username                        = local.username
  password                        = random_password.rds_password.result
  vpc_security_group_ids          = [aws_security_group.igdb.id]
  #?skip_final_snapshot             = false
  #?final_snapshot_identifier       = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name            = aws_db_parameter_group.igdb-parametergroup-19c.name
  db_subnet_group_name            = aws_db_subnet_group.igdb.name
  maintenance_window              = local.maintenance_window
  license_model                   = "bring-your-own-license"
  deletion_protection             = true
  copy_tags_to_snapshot           = true
  storage_encrypted               = true
  #?apply_immediately               = true
  snapshot_identifier             = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id,local.rds_snapshot_name)
  kms_key_id                      = data.aws_kms_key.rds_shared.arn
  publicly_accessible             = false
  allow_major_version_upgrade     = true
  multi_az                        = false
  option_group_name               = aws_db_option_group.PortalIGDB19OptionGroup.name





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


resource "aws_route53_record" "IGDBDbDNSRecord" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.appdb1.address]
}