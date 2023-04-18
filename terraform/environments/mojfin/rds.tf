
locals {
  cidr_ire_workspace ="10.200.96.0/19"
  cidr_six_degrees=   "10.225.60.0/24"
  pOBIEEInboundCIDR=  "10.225.40.0/24"
  pEnvManagementCIDR= "10.200.16.0/20"
  pVPCCidr=           "10.205.0.0/20"
  pCPVPCCidr=         "172.20.0.0/20"
  transit_gw_to_mojfinprod=             "10.201.0.0/16"

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
