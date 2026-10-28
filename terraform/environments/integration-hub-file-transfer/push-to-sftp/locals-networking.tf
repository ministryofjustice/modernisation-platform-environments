locals {
  private_subnet_ids = sort(data.aws_subnets.shared-private.ids)

  https_egress_rules = {
    for subnet_id, subnet in data.aws_subnet.shared_protected : "https-${subnet_id}" => {
      name        = "${local.pattern_name}-https"
      description = "HTTPS to shared protected VPC endpoint subnets"
      cidr_ipv4   = subnet.cidr_block
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
    }
  }

  sftp_targets = distinct(flatten([
    for destination in values(local.sftp_destinations_by_secret) : [
      for cidr in destination.destination_cidr_blocks : {
        cidr = cidr
        port = destination.port
      }
    ]
  ]))

  sftp_egress_rules = {
    for target in local.sftp_targets : "${target.cidr}:${target.port}" => {
      name        = "${local.pattern_name}-sftp"
      description = "Approved recipient SFTP endpoint"
      cidr_ipv4   = target.cidr
      ip_protocol = "tcp"
      from_port   = target.port
      to_port     = target.port
    }
  }

  writer_egress_rules = merge(
    local.https_egress_rules,
    local.sftp_egress_rules,
  )
}