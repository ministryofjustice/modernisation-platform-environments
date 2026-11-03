data "aws_subnets" "shared_protected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-protected*"
  }
}

data "aws_subnet" "shared_protected" {
  for_each = toset(data.aws_subnets.shared_protected.ids)
  id       = each.value
}

data "aws_ec2_managed_prefix_list" "aws_services" {
  for_each = toset(["s3", "dynamodb"])

  name = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
}

locals {
  private_subnet_ids = sort(data.aws_subnets.shared-private.ids)

  protected_subnet_https_egress_rules = {
    for subnet_id, subnet in data.aws_subnet.shared_protected : "https-${subnet_id}" => {
      name        = "${local.pattern_name}-https"
      description = "HTTPS to shared protected VPC endpoint subnets"
      cidr_ipv4   = subnet.cidr_block
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
    }
  }

  prefix_list_egress_rules = {
    for service, prefix_list in data.aws_ec2_managed_prefix_list.aws_services : "https-${service}" => {
      name           = "${local.pattern_name}-${service}-https"
      description    = "HTTPS to the regional ${service} managed prefix list"
      prefix_list_id = prefix_list.id
      ip_protocol    = "tcp"
      from_port      = 443
      to_port        = 443
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

  egress_rules = merge(
    local.protected_subnet_https_egress_rules,
    local.prefix_list_egress_rules,
    local.sftp_egress_rules,
  )
}