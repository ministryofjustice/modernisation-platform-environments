module "security_group_writer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name            = local.pattern_name
  use_name_prefix = false
  description     = "Outbound SFTP delivery and HTTPS to shared protected subnets; no inbound access"
  vpc_id          = data.aws_vpc.shared.id

  ingress_rules = {}
  egress_rules = merge({
    for key, rule in local.sftp_egress_rules : key => {
      name        = "${local.pattern_name}-sftp"
      description = "Approved recipient SFTP endpoint"
      cidr_ipv4   = rule.cidr
      ip_protocol = "tcp"
      from_port   = rule.port
      to_port     = rule.port
    }
    }, {
    for subnet_id, subnet in data.aws_subnet.shared-protected : "https-${subnet_id}" => {
      name        = "${local.pattern_name}-https"
      description = "HTTPS to shared protected VPC endpoint subnets"
      cidr_ipv4   = subnet.cidr_block
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
    }
  })

  tags = merge(local.tags, { Name = local.pattern_name })
}