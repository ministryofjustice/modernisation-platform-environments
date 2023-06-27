data "aws_vpc" "dpr" {
  id = local.dpr_vpc
}

## Lambda Generic SG
resource "aws_security_group" "lambda_generic" {
  name_prefix = "${local.generic_lambda}-sg"
  description = "Generic Lambda Security Group"
  vpc_id      = local.dpr_vpc # Lambda VPC

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Resource_Type = "sg_group"
      Name          = "${local.generic_lambda}-sg"
    }
  )
}

resource "aws_security_group_rule" "lambda_ingress_generic" {
  count = var.enable_sg_group ? 1 : 0

  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda[0].id
}

resource "aws_security_group_rule" "lambda_egress_generic" {
  count = var.enable_sg_group ? 1 : 0

  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_generic[0].id
}
