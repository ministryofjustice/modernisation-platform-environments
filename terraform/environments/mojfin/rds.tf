resource "aws_db_subnet_group" "mojfin" {
  name       = "${local.application_name}-${local.environment}-subnetgrp"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp" },
    { "Keep" = "true" }

  )

}

resource "aws_db_parameter_group" "mojfin" {
  name        = "${local.application_name}-${local.environment}-parametergroup"
  family      = "oracle-se2-19"
  description = "${local.application_name}-${local.environment}-parametergroup"


  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "8"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-parametergroup" },
    { "Keep" = "true" }
  )
}

resource "aws_security_group" "mojfin" {
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
    description = "Connectivity Analytic Platform use of Transit Gateway to MoJFin PROD"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.transit_gw_to_mojfinprod]

  }

  ingress {
    description = "Connectivity from MP Environment VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }


  ingress {
    description = "Temp rule for DBlinks, remove rule once the other DBs have been migrated to MP"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.lzprd-vpc]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-mojfin" }
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
  max_allocated_storage           = local.max_allocated_storage
  username                        = local.username
  password                        = random_password.rds_password.result
  vpc_security_group_ids          = [aws_security_group.mojfin.id]
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name            = aws_db_parameter_group.mojfin.name
  db_subnet_group_name            = aws_db_subnet_group.mojfin.name
  maintenance_window              = local.maintenance_window
  license_model                   = "license-included"
  deletion_protection             = true
  copy_tags_to_snapshot           = true
  storage_encrypted               = true
  apply_immediately               = true
  #snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id,local.rds_snapshot_name)
  kms_key_id = data.aws_kms_key.rds_shared.arn


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


resource "aws_route53_record" "prd-mojfin-rds" {
  count    = local.environment == "production" ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.laa-finance.zone_id
  name     = "rds.${local.prod_domain_name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.appdb1.address]
}

resource "aws_route53_record" "nonprd-mojfin-rds" {
  count    = local.environment != "production" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.appdb1.address]
}
