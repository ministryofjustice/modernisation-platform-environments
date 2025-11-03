resource "aws_security_group" "tariff_app_prod_security_group" {
  name_prefix = "${local.application_name}-app-server-sg-${local.environment}"
  description = "Access to the app server"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-server-sg-${local.environment}" }
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
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b, local.cidr_cica_prod_a, local.cidr_cica_prod_b]
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b, local.cidr_cica_prod_a, local.cidr_cica_prod_b]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1521
    to_port     = 1521
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b, local.cidr_cica_ras, local.cidr_cica_lan, local.cidr_cica_ras_nat, local.cidr_cica_prod_a, local.cidr_cica_prod_b]

  }

  #Allow ingress to weblogic
  ingress {
    protocol    = "tcp"
    from_port   = 7001
    to_port     = 7002
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ras, local.cidr_cica_lan, local.cidr_cica_ras_nat, local.cidr_cica_prod_a, local.cidr_cica_prod_b]

  }

  #Allow ingress to reports
  ingress {
    protocol    = "tcp"
    from_port   = 8001
    to_port     = 8002
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ras, local.cidr_cica_lan, local.cidr_cica_ras_nat, local.cidr_cica_prod_a, local.cidr_cica_prod_b]

  }

  ingress {
    protocol  = "tcp"
    from_port = 9000
    to_port   = 65500
    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

  #Commvault ports from SS
  ingress {
    protocol    = "tcp"
    from_port   = 8400
    to_port     = 8403
    cidr_blocks = [local.cidr_cica_ss_a, local.cidr_cica_ss_b]
    description = "Allow Commvault inbound from Shared Services"
  }
}
