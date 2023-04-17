



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
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].lz_vpc_cidr]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.lz_vpc_cidr]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-laalz-secgroup"
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

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-vpc-secgroup"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.appdb1.address
}