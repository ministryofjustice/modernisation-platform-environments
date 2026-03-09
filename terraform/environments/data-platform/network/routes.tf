resource "aws_route" "public_internet_gateway" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }

  route_table_id         = aws_route_table.main["public-${each.key}"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Public to private subnet route forces ingress traffic (e.g., NLB → backend)
# through Network Firewall for inspection. Without this, traffic would use
# the implicit local route and bypass the firewall entirely.
resource "aws_route" "public_to_private_subnets" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }

  route_table_id         = aws_route_table.main["public-${each.key}"].id
  destination_cidr_block = aws_subnet.main["private-${each.key}"].cidr_block
  vpc_endpoint_id        = data.aws_vpc_endpoint.network_firewall[each.key].id

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route" "firewall_to_nat_gateway" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }

  route_table_id         = aws_route_table.main["firewall-${each.key}"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.key].id
}

resource "aws_route" "private_to_network_firewall" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "private"
  }

  route_table_id         = aws_route_table.main["private-${each.key}"].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = data.aws_vpc_endpoint.network_firewall[each.key].id

  depends_on = [aws_networkfirewall_firewall.main]
}

module "firewall_transit_gateway_routes" {
  for_each = length(local.transit_gateway_routes) > 0 ? {
    for key, value in local.subnets : value.az => value
    if value.type == "firewall"
  } : {}

  source = "./modules/aws/transit-gateway/routes"

  route_table_id          = aws_route_table.main["firewall-${each.key}"].id
  destination_cidr_blocks = values(local.transit_gateway_routes)
  transit_gateway_id      = data.aws_ec2_transit_gateway.moj_tgw.id
}

resource "aws_route" "transit_gateway_to_network_firewall" {
  for_each = length(local.transit_gateway_routes) > 0 ? {
    for key, value in local.additional_cidr_subnets : key => value
    if value.type == "attachments"
  } : {}

  route_table_id         = aws_route_table.additional[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = data.aws_vpc_endpoint.network_firewall[each.value.az].id

  depends_on = [aws_networkfirewall_firewall.main]
}
