data "aws_vpc" "dpr" {
  id = local.dpr_vpc
}

## Lambda Generic SG
resource "aws_security_group" "lambda_generic" {
  #checkov:skip=CKV2_AWS_5

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
      dpr-resource-type     = "sg_group"
      dpr-name              = "${local.generic_lambda}-sg"
      dpr-is-service-bundle = true
      dpr-domain            = "Common"
      dpr-domain-category   = "Common"
      dpr-jira              = "DPR2-XXXX"
    }
  )
}

resource "aws_security_group_rule" "lambda_ingress_generic" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"

  count = local.enable_generic_lambda_sg ? 1 : 0

  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_generic[0].id
}

resource "aws_security_group_rule" "lambda_egress_generic" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
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
  #checkov:skip=CKV2_AWS_5

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
      dpr-resource-type = "sg_group"
      dpr-name          = "${local.serverless_gw_dbuilder_name}-sg"
    }
  )
}

resource "aws_security_group_rule" "serverless_gw_ingress" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"

  count = local.enable_dbuilder_serverless_gw ? 1 : 0

  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  security_group_id = aws_security_group.serverless_gw[0].id
}

resource "aws_security_group_rule" "serverless_gw_egress" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
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
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"

  count = local.include_dbuilder_gw_vpclink ? 1 : 0

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
      dpr-resource-type = "sg_group"
      dpr-name          = "${local.serverless_gw_dbuilder_name}-sg-${local.env}"
    }
  )
}