data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

# OPAHUB ALB Security Group

resource "aws_security_group" "alb_opahub" {
  name        = "${local.opahub_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.opahub_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.opahub_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_opahub_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb_opahub.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_opahub_egress_ec2" {
  security_group_id            = aws_security_group.alb_opahub.id
  description                  = "Allow LB to reach EC2 cluster ephemeral ports"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

# Connector ALB Security Group

resource "aws_security_group" "alb_connector" {
  name        = "${local.connector_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.connector_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.connector_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_connector_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb_connector.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_connector_egress_ec2" {
  security_group_id            = aws_security_group.alb_connector.id
  description                  = "Allow LB to reach EC2 cluster ephemeral ports"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

# Adaptor ALB Security Group

resource "aws_security_group" "alb_adaptor" {
  name        = "${local.adaptor_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.adaptor_name} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.adaptor_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_adaptor_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb_adaptor.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_adaptor_egress_ec2" {
  security_group_id            = aws_security_group.alb_adaptor.id
  description                  = "Allow LB to reach EC2 cluster ephemeral ports"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

# ECS Cluster EC2 Security Group

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  description = "Controls access to the ${local.component_name} ECS cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_from_alb_opahub" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Ephemeral port traffic from OPAHUB ALB"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.alb_opahub.id
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_from_alb_connector" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Ephemeral port traffic from Connector ALB"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.alb_connector.id
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_from_alb_adaptor" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Ephemeral port traffic from Adaptor ALB"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.alb_adaptor.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS Security Group

resource "aws_security_group" "rds" {
  name        = "${local.component_name}-${local.env_label}-rds-sg"
  description = "Controls access to the ${local.component_name} MySQL RDS instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_private_subnets" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.rds.id
  description       = "MySQL from private subnets"
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_cluster_ec2" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from ECS cluster EC2 instances"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EFS Security Group

resource "aws_security_group" "efs" {
  name        = "${local.component_name}-${local.env_label}-efs-sg"
  description = "Controls NFS access to the ${local.component_name} EFS file system"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-efs-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_cluster_ec2" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from ECS cluster EC2 instances"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

resource "aws_vpc_security_group_egress_rule" "efs_egress_all" {
  security_group_id = aws_security_group.efs.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
