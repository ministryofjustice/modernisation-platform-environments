data "aws_vpc" "dpr" {
    id = var.vpc_id
}

## RDS SG
resource "aws_security_group" "rds" {
  count = var.enabled ? 1 : 0

  name_prefix = "${var.name}-sg"
  description = "RDS VPC Endpoint Security Group"
  vpc_id      = var.vpc_id # RDS VPC

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(tomap({
    "Component" = "Security Group" }),
    var.tags,
  )
}

resource "aws_security_group_rule" "rule" {
  count             = var.enable_rds ? 1 : 0

  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 5432
  to_port           = 5432
  security_group_id = aws_security_group.rds[0].id
}

resource "aws_security_group_rule" "rds_allow_all" {
  count             = var.enable_rds ? 1 : 0

  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds[0].id
}
