locals {
  mojfin_allowed_cidrs = [
    "51.149.251.0/24",
    "51.149.250.0/24",
    "51.149.249.0/29",
    "194.33.249.0/29",
    "51.149.249.32/29",
    "194.33.248.0/29",
    "128.77.75.64/26",
    "20.49.214.199/32",
    "20.49.214.228/32",
    "20.26.11.71/32",
    "20.26.11.108/32",
    "18.169.147.172/32",
    "35.176.93.186/32",
    "18.130.148.126/32",
    "35.176.148.126/32",
    "13.41.38.176/32",
    "3.11.197.133/32",
    "3.8.81.175/32",
    "13.42.163.245/32",
    "13.43.9.198/32",
    "18.132.208.127/32",
    "35.178.209.113/32",
    "3.8.51.207/32",
    "35.177.252.54/32",
    "35.176.127.232/32",
    "18.130.39.94/32",
    "35.177.145.193/32",
    "35.176.254.38/32",
    "52.56.212.11/32",
    "35.177.173.197/32",
    "10.148.0.0/14",
  ]
}
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
    for_each = local.environment != "production" ? [] : [local.mojo_vpc_cidr] # only applying this rule in production
    content {
      description = "MoJ Official Device Traffic inbound"
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
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

  dynamic "ingress" {
    for_each = local.environment == "production" ? [1] : []
    content {
      description = "Custom allowed CIDRs for MOJO devices - only applied in production"
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      cidr_blocks = local.mojfin_allowed_cidrs
    }
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-mojfin" }
  )
}
