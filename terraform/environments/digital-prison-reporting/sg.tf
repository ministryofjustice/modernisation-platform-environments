data "aws_vpc" "dpr" {
  id = local.dpr_vpc
}

## Lambda Generic SG
resource "aws_security_group" "lambda_generic" {
  count = local.enable_generic_lambda_sg ? 1 : 0

  name_prefix = "${local.generic_lambda}-sg"
  description = "Generic Lambda Security Group"
  vpc_id      = local.dpr_vpc # Lambda VPC

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.all_tags,
    {
      Resource_Type = "sg_group"
      Name          = "${local.generic_lambda}-sg"
    }
  )
}

resource "aws_security_group_rule" "lambda_ingress_generic" {
  count = local.enable_generic_lambda_sg ? 1 : 0

  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_generic[0].id
}

resource "aws_security_group_rule" "lambda_egress_generic" {
  count = local.enable_generic_lambda_sg ? 1 : 0

  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_generic[0].id
}

## Serverless Lambda GW VPC Link SG
resource "aws_security_group" "serverless_gw" {
  count = local.enable_dbuilder_serverless_gw ? 1 : 0

  name_prefix = "${local.serverless_gw_dbuilder_name}-sg"
  description = "Serverless GW Security Group"
  vpc_id      = local.dpr_vpc # DPR VPC

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.all_tags,
    {
      Resource_Type = "sg_group"
      Name          = "${local.serverless_gw_dbuilder_name}-sg"
    }
  )
}

resource "aws_security_group_rule" "serverless_gw_ingress" {
  count = local.enable_dbuilder_serverless_gw ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.serverless_gw[0].id
}

resource "aws_security_group_rule" "serverless_gw_egress" {
  count = local.enable_dbuilder_serverless_gw ? 1 : 0

  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.serverless_gw[0].id
}

# VPC Gateway Endpoint SG
resource "aws_security_group" "gateway_endpoint_sg" {
  count       = local.include_dbuilder_gw_vpclink ? 1 : 0

  name        = "${local.serverless_gw_dbuilder_name}-sg"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = local.dpr_vpc # DPR VPC

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.dpr.cidr_block, ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.all_tags,
    {
      Resource_Type = "sg_group"
      Name          = "${local.serverless_gw_dbuilder_name}-sg-${local.env}"
    }
  )
}