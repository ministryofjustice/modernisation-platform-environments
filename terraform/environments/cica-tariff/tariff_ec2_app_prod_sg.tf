module "tariff_app_prod_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa"
  # version = "5.3.1"
  count       = local.environment == "production" ? 1 : 0
  name        = "${local.application_name}-app-server-sg-${local.environment}"
  description = "Access to the app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    { "Name" = "${local.application_name}-app-server-sg-${local.environment}" },
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
        local.cidr_cica_prod_b
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
        local.cidr_cica_prod_b
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
      from_port = 8001
      to_port   = 8002
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

  ingress_with_source_security_group_id = [
    {
      rule                     = "nfs-tcp"
      source_security_group_id = module.tariff_db_prod_security_group[0].security_group_id
      description              = "Allow NFS 2049tcp ingress from DB tier for spp_draft_letters mount"
    },
    {
      from_port                = 111
      to_port                  = 111
      protocol                 = "tcp"
      source_security_group_id = module.tariff_db_prod_security_group[0].security_group_id
      description              = "Allow  NFS 111tcp ingress from DB tier for spp_draft_letters mount"
    },
    {
      from_port                = 111
      to_port                  = 111
      protocol                 = "udp"
      source_security_group_id = module.tariff_db_prod_security_group[0].security_group_id
      description              = "Allow  NFS 111udp ingress from DB tier for spp_draft_letters mount"
    }
  ]
}