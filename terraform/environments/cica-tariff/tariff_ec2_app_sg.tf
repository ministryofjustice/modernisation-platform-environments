resource "aws_security_group" "tariff_app_security_group" {
  name_prefix = "${local.application_name}-app-server-sg-"
  description = "Access to the app server"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-server-sg" }
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
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b]
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1521
    to_port     = 1521
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b]

  }

}


