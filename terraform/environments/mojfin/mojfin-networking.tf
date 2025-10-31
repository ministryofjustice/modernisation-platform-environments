resource "aws_db_subnet_group" "mojfin" {
  name       = "${local.application_name}-${local.environment}-subnetgrp"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-subnetgrp" },
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

  dynamic "ingress" {
    for_each = local.environment == "preproduction" ? [] : [local.cidr_ire_workspace]
    content {
      description = "Ireland Shared Services Inbound - Workspaces etc"
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
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

  dynamic "ingress" {
    for_each = local.environment == "preproduction" ? [] : [local.analytic_platform_cidr]
    content {
      description = "Connectivity Analytic Platform (Airflow) use of Transit Gateway to MoJFin"
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  ingress {
    description = "Connectivity from MP Environment VPC"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  dynamic "ingress" {
    for_each = local.environment == "preproduction" ? [] : [local.lz_vpc]
    content {
      description = "Temp rule for DBlinks, remove rule once the other DBs have been migrated to MP"
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
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
