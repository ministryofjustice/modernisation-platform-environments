resource "aws_security_group" "oem_app_security_group_1" {
  name_prefix = "${local.application_name}-app-server-sg-1-"
  description = "Access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-server-sg-1" }
  ), local.tags)

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces_nonp, local.cidr_lz_workspaces_prod]
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces_nonp, local.cidr_lz_workspaces_prod]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 1159
    to_port         = 1159
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 1521
    to_port         = 1521
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 1830
    to_port         = 1849
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 3872
    to_port         = 3872
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 4889
    to_port         = 4889
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 4903
    to_port         = 4903
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7101
    to_port         = 7102
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }
}

resource "aws_security_group" "oem_app_security_group_2" {
  name_prefix = "${local.application_name}-app-server-sg-2-"
  description = "Access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-server-sg-2" }
  ), local.tags)

  ingress {
    protocol        = "tcp"
    from_port       = 7202
    to_port         = 7202
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7301
    to_port         = 7301
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7403
    to_port         = 7403
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7788
    to_port         = 7788
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7799
    to_port         = 7799
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7803
    to_port         = 7803
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 9788
    to_port         = 9788
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 9851
    to_port         = 9851
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }
}
