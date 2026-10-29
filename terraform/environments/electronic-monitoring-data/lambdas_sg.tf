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

data "aws_prefix_list" "dynamodb" {
  name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
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

resource "aws_security_group_rule" "lambda_egress_dynamodb" {
  type              = "egress"
  description       = "allow dynamodb"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.dynamodb.id]
  security_group_id = aws_security_group.lambda_generic.id
}


resource "aws_security_group" "lambda_cp_sg" {
  name_prefix = "${local.bucket_prefix}-cloud-platform-lambda-sg"
  description = "Lambda Security Group for CP access"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cloud_platform_access" {
  type              = "egress"
  description       = "allow CP egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["172.16.0.0/12"]
  security_group_id = aws_security_group.lambda_cp_sg.id
}

resource "aws_security_group" "lambda_gov_notify_access" {

  name_prefix = "${local.bucket_prefix}-outbound-gov-notify-lambda-sg"
  description = "Gov Notify Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gov_notify_access" {
  type              = "egress"
  description       = "allow gov notify egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_gov_notify_access.id
}
