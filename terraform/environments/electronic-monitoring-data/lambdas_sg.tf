## Lambda Generic SG
resource "aws_security_group" "lambda_generic" {
  #checkov:skip=CKV2_AWS_5

  name_prefix = "${local.bucket_prefix}-generic-lambda-sg"
  description = "Generic Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lambda_ingress_generic" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, ]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_generic.id
}

resource "aws_security_group_rule" "lambda_egress_generic" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_generic.id
}
