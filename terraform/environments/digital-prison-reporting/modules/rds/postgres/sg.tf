data "aws_vpc" "dpr" {
  id = var.vpc_id
}

## RDS SG
resource "aws_security_group" "rds" {
  count = var.enable_rds ? 1 : 0

  name_prefix = "${var.name}-sg"
  description = "RDS VPC Endpoint Security Group"
  vpc_id      = var.vpc_id # RDS VPC

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Resource_Type = "sg_group"
      Name          = "${var.name}-sg"
    }
  )
}

# EC2 Security Group
resource "aws_security_group" "rds_ec2_sec_group" {
  count = var.enable_rds ? 1 : 0

  name        = "${var.name}-rds-ec2-sgroup"
  description = "RDS to EC2 security group"
  vpc_id      = data.aws_vpc.dpr.id
  tags        = var.tags
}

resource "aws_security_group_rule" "ingress_traffic_block_1" {
  count = var.enable_rds ? 1 : 0

  type              = "ingress"
  description       = "Security group rule to allow incoming connections between ports 0-21"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 21
  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  security_group_id = aws_security_group.rds_ec2_sec_group[0].id
}

resource "aws_security_group_rule" "ingress_traffic_block_2" {
  count = var.enable_rds ? 1 : 0

  type              = "ingress"
  description       = "Security group rule to allow incoming connections between ports 23-79"
  protocol          = "tcp"
  from_port         = 23
  to_port           = 79
  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  security_group_id = aws_security_group.rds_ec2_sec_group[0].id
}


resource "aws_security_group_rule" "ingress_traffic_block_3" {
  count = var.enable_rds ? 1 : 0

  type              = "ingress"
  description       = "Security group rule to allow incoming connections between ports 81-3388"
  protocol          = "tcp"
  from_port         = 81
  to_port           = 3388
  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  security_group_id = aws_security_group.rds_ec2_sec_group[0].id
}

resource "aws_security_group_rule" "ingress_traffic_block_4" {
  count = var.enable_rds ? 1 : 0

  type              = "ingress"
  description       = "Security group rule to allow incoming connections between ports 3390-65535"
  protocol          = "tcp"
  from_port         = 3390
  to_port           = 65535
  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  security_group_id = aws_security_group.rds_ec2_sec_group[0].id
}

resource "aws_security_group_rule" "rule" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"

  count = var.enable_rds ? 1 : 0

  cidr_blocks       = [data.aws_vpc.dpr.cidr_block, ]
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 5432
  to_port           = 5432
  security_group_id = aws_security_group.rds[0].id
}

resource "aws_security_group_rule" "rds_allow_all" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  count = var.enable_rds ? 1 : 0

  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds[0].id
}
