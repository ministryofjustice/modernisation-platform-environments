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


# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound IPv4 traffic"
}