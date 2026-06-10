resource "aws_security_group" "rds" {
  name        = "${local.component_name}-rds"
  description = "Security group for app RDS PostgreSQL"
  vpc_id      = data.aws_vpc.eks.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_eks" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL access from EKS pods"
  cidr_ipv4         = data.aws_vpc.eks.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}
