# OIA EC2 Instances Security Group

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_name}-cluster-ec2-security-group"
  description = "Controls access to the cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-ec2-sg", local.application_name)) }
  )
}

# INGRESS Rules

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_opahub_lb" {
  security_group_id            = aws_security_group.cluster_ec2.id
  referenced_security_group_id = aws_security_group.opahub_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65353
  description                  = "Traffic from OPAHUB ALB to OIA EC2 instances"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_connector_lb" {
  security_group_id            = aws_security_group.cluster_ec2.id
  referenced_security_group_id = aws_security_group.connector_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65353
  description                  = "Traffic from Connector ALB to OIA EC2 instances"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_service_adaptor_lb" {
  security_group_id            = aws_security_group.cluster_ec2.id
  referenced_security_group_id = aws_security_group.adaptor_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65353
  description                  = "Traffic from Service Adaptor ALB to OIA EC2 instances"
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_connector_container" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Allow OIA EC2 instances to reach Connector container port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].connector_server_port
  to_port                      = local.application_data.accounts[local.environment].connector_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks_connector.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_opa_container" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Allow OIA EC2 instances to reach OPA container port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_server_port
  to_port                      = local.application_data.accounts[local.environment].opa_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks_opa.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_adaptor_container" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Allow OIA EC2 instances to reach Service Adaptor container port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].adaptor_server_port
  to_port                      = local.application_data.accounts[local.environment].adaptor_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks_adaptor.id
}


# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_vpce" {
  for_each          = toset([
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow egress to VPC endpoints (logs/ecs/secrets)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_s3" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow S3 access via gateway endpoint (prefix list)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_443" {
  for_each          = toset([
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_mysql" {
  for_each          = toset([
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "MySQL"
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_1521" {
  for_each          = toset([
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow egress to protected subnets"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_1522" {
  for_each          = toset([
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow egress to protected subnets on port 1522"
  ip_protocol       = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_2049_efs" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Allow egress to EFS security group on port 2049"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.oia-efs-security-group.id
}