# VPC Endpoints Configuration
#
# Gateway VPC endpoints (S3, DynamoDB) are provisioned locally in this VPC
# as they don't incur data transfer costs and provide optimal routing.
#
# Interface VPC endpoints are defined centrally in the Modernisation Platform core-network-services 
# account and shared via Transit Gateway. This approach provides cost efficiency and centralised management.
# 
# For the complete list of centrally managed interface endpoints, see:
# https://github.com/ministryofjustice/modernisation-platform/blob/main/terraform/environments/core-network-services/centralised-vpc-endpoints.json
#
# A Route53 Profile from core-network-services is associated to this VPC to enable
# DNS resolution for the centrally managed interface endpoints.

### Gateway VPC Endpoints ###
module "vpc-gateway-endpoints" {
  source   = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version  = "6.5.1"
  for_each = toset(local.vpc_gateway_endpoint_service_names)

  vpc_id = module.cluster_vpc.vpc_id

  endpoints = {
    (each.value) = {
      service         = each.value
      service_type    = "Gateway"
      route_table_ids = module.cluster_vpc.private_route_table_ids
      tags = merge(
        local.tags,
        { Name = "${module.cluster_vpc.name}-${each.value}" }
      )
    }
  }
}


### Route53 Profile Association and Routes to Centralised Interface VPC Endpoints ###

# Associates the centralised Route53 Profile for DNS resolution of interface VPC endpoints
resource "aws_route53profiles_association" "cp_vpc_assoc" {
  name        = "centralised-endpoints"
  profile_id  = "rp-ac0b20868a5a4eb4"
  resource_id = module.cluster_vpc.vpc_id
}

# Routes to centralised interface VPC endpoints (10.20.240.0/20) via Transit Gateway
resource "aws_route" "private_subnet_to_vpc_interface_endpoints_mp" {
  count                  = length(module.cluster_vpc.private_route_table_ids)
  route_table_id         = module.cluster_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "10.20.240.0/20"
  transit_gateway_id     = "tgw-053d9dd7f1222a554"
}