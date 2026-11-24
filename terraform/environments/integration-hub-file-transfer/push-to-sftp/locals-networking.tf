# Interface endpoints are owned by core-vpc and not RAM-shared into member accounts.
data "aws_security_group" "shared_interface_endpoints" {
  provider = aws.core-vpc
  vpc_id   = data.aws_vpc.shared.id

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-int-endpoint"
  }
}

data "aws_ec2_managed_prefix_list" "aws_services" {
  for_each = toset(["s3", "dynamodb"])

  name = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
}

locals {
  private_subnet_ids = sort(data.aws_subnets.shared-private.ids)

  sftp_targets = distinct(flatten([
    for destination in values(local.sftp_destinations_by_secret) : [
      for cidr in destination.destination_cidr_blocks : {
        cidr = cidr
        port = destination.port
      }
    ]
  ]))

  egress_rules = merge(
    {
      "https-interface-endpoints" = {
        name                         = "${local.pattern_name}-interface-endpoints-https"
        description                  = "HTTPS to shared VPC interface endpoints"
        referenced_security_group_id = data.aws_security_group.shared_interface_endpoints.id
        ip_protocol                  = "tcp"
        from_port                    = 443
        to_port                      = 443
      }
    },
    {
      for service, prefix_list in data.aws_ec2_managed_prefix_list.aws_services : "https-${service}" => {
        name           = "${local.pattern_name}-${service}-https"
        description    = "HTTPS to the regional ${service} managed prefix list"
        prefix_list_id = prefix_list.id
        ip_protocol    = "tcp"
        from_port      = 443
        to_port        = 443
      }
    },
    {
      for target in local.sftp_targets : "${target.cidr}:${target.port}" => {
        name        = "${local.pattern_name}-sftp"
        description = "Approved recipient SFTP endpoint"
        cidr_ipv4   = target.cidr
        ip_protocol = "tcp"
        from_port   = target.port
        to_port     = target.port
      }
    },
  )
}