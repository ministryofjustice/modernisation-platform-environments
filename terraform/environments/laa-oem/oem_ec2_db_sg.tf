resource "aws_security_group" "oem_db_security_group" {
  name_prefix = "${local.application_name}-db-server-sg-"
  description = "controls access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-server-sg-1" }
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
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1159
    to_port     = 1159
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1521
    to_port     = 1521
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1830
    to_port     = 1849
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 3872
    to_port     = 3872
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4889
    to_port     = 4889
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 7101
    to_port     = 7101
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 7799
    to_port     = 7799
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }
}
