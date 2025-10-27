resource "aws_security_group" "lambda_generic" {

  name_prefix = "${local.bucket_prefix}-generic-lambda-sg"
  description = "Generic Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

# get s3 endpoint
data "aws_vpc_endpoint" "s3" {
  provider     = aws.core-vpc
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_id       = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.s3"
  }
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_security_group_rule" "lambda_ingress_generic" {
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, ]
  type              = "ingress"
  description       = "allow all"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_generic.id
}

resource "aws_security_group_rule" "lambda_ingress_s3" {
  type              = "ingress"
  description       = "allow s3"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
  security_group_id = aws_security_group.lambda_generic.id
}

resource "aws_security_group_rule" "lambda_egress_generic" {
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, ]
  security_group_id = aws_security_group.lambda_generic.id
}

resource "aws_security_group_rule" "lambda_egress_s3" {
  type              = "egress"
  description       = "allow s3"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
  security_group_id = aws_security_group.lambda_generic.id
}

# DMS Validation 

resource "aws_security_group" "dms_validation_lambda_sg" {
  count       = local.is-production || local.is-development ? 1 : 0
  name_prefix = "${local.bucket_prefix}-dms-validation-lambda-sg"
  description = "DMS Validation Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "dms_validation_lambda_egress_s3" {
  count             = local.is-production || local.is-development ? 1 : 0
  type              = "egress"
  description       = "allow s3"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
  security_group_id = aws_security_group.dms_validation_lambda_sg[0].id
}

resource "aws_vpc_security_group_egress_rule" "dms_validation_lambda_egress_RDS" {
  count                        = local.is-production || local.is-development ? 1 : 0
  security_group_id            = aws_security_group.dms_validation_lambda_sg[0].id
  referenced_security_group_id = aws_security_group.db[0].id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "Lambda -----[mssql]-----+ RDS Database"
}

resource "aws_vpc_security_group_ingress_rule" "dms_validation_lambda_ingress_RDS" {
  count                        = local.is-production || local.is-development ? 1 : 0
  security_group_id            = aws_security_group.db[0].id
  referenced_security_group_id = aws_security_group.dms_validation_lambda_sg[0].id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "RDS Database +-----[mssql]----- Lambda"
}

resource "aws_security_group_rule" "dms_validation_lambda_ingress_generic" {
  count             = local.is-production || local.is-development ? 1 : 0
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, ]
  type              = "ingress"
  description       = "allow all"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.dms_validation_lambda_sg[0].id
}

resource "aws_security_group_rule" "dms_validation_lambda_egress_generic" {
  count             = local.is-production || local.is-development ? 1 : 0
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, ]
  security_group_id = aws_security_group.dms_validation_lambda_sg[0].id
}
