# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_s3" {
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name        = "allow-s3-egress-from-flink"
  description = "Allow HTTPS egress traffic to s3 from flink applications"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.extended_tags, {
    Name = "allow-s3-egress-from-flink"
  })
}

resource "aws_vpc_security_group_egress_rule" "egress_to_s3" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.allow_s3[0].id
  description       = "Allow HTTPS egress traffic to s3 from flink applications"

  from_port      = 443
  to_port        = 443
  ip_protocol    = "tcp"
  prefix_list_id = data.aws_prefix_list.s3.id

  tags = merge(local.extended_tags, {
    Name = "allow-s3-egress-from-flink"
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# TODO: Remove this security group once MSK is deployed to the shared account
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_msk" {
  count       = contains(local.deploy_to, local.environment) ? 1 : 0
  name        = "allow-msk-egress-from-flink"
  description = "Allow egress to MSK Serverless cluster - VPC only access"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.extended_tags, {
    Name = "allow-msk-egress-from-flink"
  })
}

resource "aws_vpc_security_group_ingress_rule" "msk_iam_auth" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.allow_msk[0].id
  description       = "IAM SASL authentication from VPC"

  from_port   = 9098
  to_port     = 9098
  ip_protocol = "tcp"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block

  tags = merge(local.extended_tags, {
    Name = "msk-iam-auth"
  })
}

resource "aws_vpc_security_group_egress_rule" "msk_outbound_vpc" {
  count             = contains(local.deploy_to, local.environment) ? 1 : 0
  security_group_id = aws_security_group.allow_msk[0].id
  description       = "Allow outbound within VPC only"

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = data.aws_vpc.shared.cidr_block

  tags = merge(local.extended_tags, {
    Name = "msk-outbound-vpc"
  })
}
# ---------------------------------------------------------------------------------------------------------------------
