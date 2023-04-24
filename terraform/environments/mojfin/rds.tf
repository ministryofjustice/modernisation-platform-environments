
locals {
  cidr_ire_workspace ="10.200.96.0/19"
  cidr_six_degrees=   "10.225.60.0/24"
  pOBIEEInboundCIDR=  "10.225.40.0/24"
  pEnvManagementCIDR= "10.200.16.0/20"
  pVPCCidr=           "10.205.0.0/20"
  pCPVPCCidr=         "172.20.0.0/20"
  transit_gw_to_mojfinprod=             "10.201.0.0/16"
  pStorageSize = "2500"
  pAppName= "mojfin"
  auto_minor_version_upgrade = false
  backup_retention_period= "35"
  character_set_name = "WE8MSWIN1252"
  instance_class= "db.m5.large"
  engine= "oracle-se2"
  engine_version = "19.0.0.0.ru-2020-04.rur-2020-04.r1"
  username= "sysdba"
  max_allocated_storage=  "3500"
  backup_window = "22:00-01:00"
  maintenance_window = "Mon:01:15-Mon:06:00"
  storage_type = "gp2"
  rds_snapshot_name= "laws3169-mojfin-migration-v1"
}


resource "aws_db_subnet_group" "appdbsubnetgroup" {
  name       = "${local.application_name}-${local.environment}-subnetgrp"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

 tags = merge(
    local.tags, 
   { "Name" = "${local.application_name}-${local.environment}-subnetgrp"},
    {"Keep" = "true"}

 )

}

resource "aws_db_parameter_group" "default" {
  name   = "rds-oracle"
  family = "oracle-se2-19"
  description = "${local.application_name}-${local.environment}-parametergroup"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = merge(
    local.tags, 
   { "Name" = "mojfinsubnetgrp"},
    {"Keep" = "true"}
 )
}

resource "aws_security_group" "laalz-secgroup" {
  name        = "laalz-secgroup"
  description = "RDS access with the LAA Landing Zone"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Ireland Shared Services Inbound - Workspaces etc"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidr_ire_workspace ]
  
  }
  ingress {
    description = "6 Degrees VPN Inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidr_six_degrees]
  
  }
 ingress {
    description ="6 Degrees OBIEE Inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.pOBIEEInboundCIDR]
  
  }
   ingress {
    description ="SharedServices Inbound - Workspaces etc"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.pEnvManagementCIDR]
  
  }
   ingress {
    description ="VPC Internal Traffic inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.pVPCCidr]
  
  }
  ingress {
    description ="Cloud Platform VPC Internal Traffic inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.pCPVPCCidr]
  
  }
  ingress {
    description ="Connectivity Analytic Platform use of Transit Gateway to MoJFin PROD"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.transit_gw_to_mojfinprod]
  
  }



  tags = {
    Name = "${local.application_name}-${local.environment}-laalz-secgroup"
  }
}



resource "aws_security_group" "vpc-secgroup" {
  name        = "vpc-secgroup"
  description = "RDS Access with the shared vpc"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }
  ingress {
    description = "6 Degrees VPN Inbound"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.cidr_six_degrees]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  tags = {
    Name = "${local.application_name}-${local.environment}-vpc-secgroup"
  }
}

resource "random_password" "rds_password" {
  length  = 16
  special = false
}


resource "aws_secretsmanager_secret" "rds_password_secret" {
  name        = "${local.application_name}/app/db-master-password-tmp2" # TODO This name needs changing back to without -tmp2 to be compatible with hardcoded OAS installation
  description = "This secret has a dynamically generated password."
  tags = merge(
    local.tags, 
    { "Name" = "${local.application_name}/app/db-master-password-tmp2" }, # TODO This name needs changing back to without -tmp2 to be compatible with hardcoded OAS installation
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
  allocated_storage           = local.pStorageSize
  db_name                     = upper(local.pAppName)
  identifier                  = local.pAppName
  engine                      = local.engine
  engine_version              = local.engine_version
  enabled_cloudwatch_logs_exports = ["alert", "audit"]
  performance_insights_enabled = true
  instance_class              = local.instance_class
  auto_minor_version_upgrade  = local.auto_minor_version_upgrade
  storage_type                = local.storage_type
  backup_retention_period     = local.backup_retention_period
  backup_window               = local.backup_window
  character_set_name          = local.character_set_name
  max_allocated_storage       = local.max_allocated_storage
  username                    = local.username
  password                    = random_password.rds_password.result
  vpc_security_group_ids      = [aws_security_group.laalz-secgroup.id, aws_security_group.vpc-secgroup.id]
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name        = "rds-oracle"
  db_subnet_group_name        = "${local.application_name}-${local.environment}-subnetgrp"
  license_model               = "license-included"
  deletion_protection         = true
  copy_tags_to_snapshot       = true
  storage_encrypted           = true
  apply_immediately           = true
  snapshot_identifier         = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id,local.rds_snapshot_name)
  kms_key_id                  = data.aws_kms_key.rds_shared.arn
  

  timeouts {
    create = "60m"
    delete = "2h"
  }

  tags = merge(
    local.tags, 
   { "Name" = "mojfin"},
    {"Keep" = "true"}
 )

}


resource "aws_route53_record" "mojfin-rds" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [format("arn:aws:rds:eu-west-2:%s:db:%s", local.environment_management.account_ids,local.application_name)]
}