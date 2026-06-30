# Interface VPC endpoints are defined centrally in the Modernisation Platform core-network-services account

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
