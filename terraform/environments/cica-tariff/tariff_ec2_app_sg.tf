module "tariff_app_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa"
  # version = "5.3.1"
  count       = local.environment != "production" ? 1 : 0
  name        = "${local.application_name}-app-server-sg"
  description = "Access to the app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    { "Name" = "${local.application_name}-app-server-sg" },
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
        local.cidr_cica_uat_a,
        local.cidr_cica_uat_b,
        local.cidr_cica_onprem_uat
      ])
    },
    {
      rule = "all-icmp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ss_a,
        local.cidr_cica_ss_b,
        local.cidr_cica_uat_a,
        local.cidr_cica_uat_b,
        local.cidr_cica_uat_c,
        local.cidr_cica_uat_d,
        local.cidr_cica_onprem_uat
      ])
    },
    {
      rule = "oracle-db-tcp"
      cidr_blocks = join(",", concat([
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ss_a,
        local.cidr_cica_ss_b,
        local.cidr_cica_uat_a,
        local.cidr_cica_uat_b,
        local.cidr_cica_uat_c,
        local.cidr_cica_uat_d,
        local.cidr_cica_dev_a,
        local.cidr_cica_dev_b,
        local.cidr_cica_dev_c,
        local.cidr_cica_dev_d,
        local.cidr_cica_ras_nat
      ], local.cidr_analytics))
    },
    {
      from_port = 7001
      to_port   = 7002
      protocol  = "tcp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ras,
        local.cidr_cica_lan,
        local.cidr_cica_ras_nat
      ])
    },
    {
      from_port = 8001
      to_port   = 8002
      protocol  = "tcp"
      cidr_blocks = join(",", [
        data.aws_vpc.shared.cidr_block,
        local.cidr_cica_ras,
        local.cidr_cica_lan,
        local.cidr_cica_ras_nat
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
}
