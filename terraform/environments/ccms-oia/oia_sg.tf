#######################################
# OIA EC2 Instances Security Group
#######################################

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_name}-cluster-ec2-security-group"
  description = "Controls access to the cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-ec2-sg", local.application_name)) }
  )
}

resource "aws_security_group_rule" "cluster_ec2_ingress_opahub_lb" {
  security_group_id        = aws_security_group.cluster_ec2.id
  type                     = "ingress"
  description              = "Traffic from OPAHUB ALB to OIA EC2 instances"
  protocol                 = "TCP"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.opahub_load_balancer.id
}

resource "aws_security_group_rule" "cluster_ec2_ingress_connector_lb" {
  security_group_id        = aws_security_group.cluster_ec2.id
  type                     = "ingress"
  description              = "Traffic from Connector ALB to OIA EC2 instances"
  protocol                 = "TCP"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.connector_load_balancer.id
}

resource "aws_security_group_rule" "cluster_ec2_ingress_service_adaptor_lb" {
  security_group_id        = aws_security_group.cluster_ec2.id
  type                     = "ingress"
  description              = "Traffic from Service Adaptor ALB to OIA EC2 instances"
  protocol                 = "TCP"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.adaptor_load_balancer.id
}

resource "aws_security_group_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
