resource "aws_security_group" "tariff_db_prod_security_group" {
  count       = local.environment == "production" ? 1 : 0
  name_prefix = "${local.application_name}-db-server-sg-${local.environment}"
  description = "Access to the database server"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-server-sg-${local.environment}" }
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
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b, local.cidr_cica_prod_a, local.cidr_cica_prod_b, local.cidr_cica_prod_c, local.cidr_cica_prod_d]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1521
    to_port     = 1521
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_cica_ss_a, local.cidr_cica_ss_b, local.cidr_cica_ras, local.cidr_cica_lan, local.cidr_cica_ras_nat, local.cidr_cica_prod_a, local.cidr_cica_prod_b, local.cidr_cica_prod_c, local.cidr_cica_prod_d]

  }

  #Allow ingress to weblogic
  ingress {
    protocol    = "tcp"
    from_port   = 7001
    to_port     = 7002
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
  #Allow connectivity between db instances
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    self        = true
    description = "Allow all traffic between db instances"
  }

  # Allow Commvault ingress from Shared Services
  ingress {
    protocol    = "tcp"
    from_port   = 8400
    to_port     = 8403
    cidr_blocks = [local.cidr_cica_ss_a, local.cidr_cica_ss_b]
    description = "Allow Commvault inbound from Shared Services"
  }
}

module "tariff_db_prod_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa"
  # version = "5.3.1"
  count       = local.environment == "production" ? 1 : 0
  name        = "${local.application_name}-db-server-sg-${local.environment}"
  description = "Access to the database server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    { "Name" = "${local.application_name}-db-server-sg-${local.environment}" },
    local.tags
  )

  egress_rules            = ["all-all"]
  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = []

  ingress_with_cidr_blocks = [
    {
      rule = "ssh-tcp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ss_a,
        local.cidr_cica_ss_b,
        local.cidr_cica_prod_a,
        local.cidr_cica_prod_b
      ])
    },
    {
      rule = "all-icmp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ss_a,
        local.cidr_cica_ss_b,
        local.cidr_cica_prod_a,
        local.cidr_cica_prod_b,
        local.cidr_cica_prod_c,
        local.cidr_cica_prod_d
      ])
    },
    {
      rule = "oracle-db-tcp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ss_a,
        local.cidr_cica_ss_b,
        local.cidr_cica_ras,
        local.cidr_cica_lan,
        local.cidr_cica_ras_nat,
        local.cidr_cica_prod_a,
        local.cidr_cica_prod_b,
        local.cidr_cica_prod_c,
        local.cidr_cica_prod_d
      ])
    },
    {
      from_port = 7001
      to_port   = 7002
      protocol  = "tcp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ras,
        local.cidr_cica_lan,
        local.cidr_cica_ras_nat,
        local.cidr_cica_prod_a,
        local.cidr_cica_prod_b
      ])
    },
    {
      from_port   = 9000
      to_port     = 65500
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port = 8400
      to_port   = 8403
      protocol  = "tcp"
      cidr_blocks = join(",", [
        local.cidr_cica_ss_a,
        local.cidr_cica_ss_b
      ])
      description = "Allow Commvault inbound from Shared Services"
    }
  ]
  ingress_with_self = [
    {
      rule        = "all-all"
      description = "Allow all traffic between db instances"
    }
  ]
}
