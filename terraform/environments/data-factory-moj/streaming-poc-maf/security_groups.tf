# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_s3" {
  name        = "allow-s3-egress-from-flink"
  description = "Allow HTTPS egress traffic to s3 from flink applications"
  vpc_id      = data.aws_vpc.shared.id

  tags = {
    Name = "allow-s3-egress-from-flink"
  }
}

resource "aws_vpc_security_group_egress_rule" "egress_to_s3" {
  security_group_id = aws_security_group.allow_s3.id
  description       = "Allow HTTPS egress traffic to s3 from flink applications"

  from_port      = 443
  to_port        = 443
  ip_protocol    = "tcp"
  prefix_list_id = data.aws_prefix_list.s3.id

  tags = {
    Name = "allow-s3-egress-from-flink"
  }
}

resource "aws_security_group" "allow_msk" {
  name        = "allow-msk-egress-from-flink"
  description = "Allow egress to MSK Serverless cluster - VPC only access"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
    description = "IAM SASL authentication from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
    description = "Allow outbound within VPC only"
  }

  tags = {
    Name = "allow-msk-egress-from-flink"
  }
}

resource "aws_vpc_security_group_egress_rule" "msk_iam_auth" {
  security_group_id = aws_security_group.allow_msk.id
  description       = "IAM SASL authentication from VPC"

  from_port   = 9098
  to_port     = 9098
  ip_protocol = "tcp"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block
}