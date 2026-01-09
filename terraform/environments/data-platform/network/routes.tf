# resource "aws_route" "public_internet_gateway" {
#   for_each = local.environment_configuration.vpc_subnets.public

#   route_table_id         = aws_route_table.main["public-${each.key}"].id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.main.id
# }

# resource "aws_route" "firewall_nat_gateway" {
#   for_each = local.environment_configuration.vpc_subnets.firewall

#   route_table_id         = aws_route_table.main["firewall-${each.key}"].id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.main[each.key].id
# }

# resource "aws_route" "private_network_firewall" {
#   for_each = local.environment_configuration.vpc_subnets.private

#   route_table_id         = aws_route_table.main["private-${each.key}"].id
#   destination_cidr_block = "0.0.0.0/0"
#   vpc_endpoint_id        = data.aws_vpc_endpoint.network_firewall[each.key].id

#   depends_on = [aws_networkfirewall_firewall.main]
# }

# resource "aws_route" "public_to_firewall_subnets" {
#   for_each = local.environment_configuration.vpc_subnets.public

#   route_table_id         = aws_route_table.main["public-${each.key}"].id
#   destination_cidr_block = aws_subnet.main["firewall-${each.key}"].cidr_block
#   vpc_endpoint_id        = data.aws_vpc_endpoint.network_firewall[each.key].id

#   depends_on = [aws_networkfirewall_firewall.main]
# }

# resource "aws_route" "public_to_private_subnets" {
#   for_each = local.environment_configuration.vpc_subnets.public

#   route_table_id         = aws_route_table.main["public-${each.key}"].id
#   destination_cidr_block = aws_subnet.main["private-${each.key}"].cidr_block
#   vpc_endpoint_id        = data.aws_vpc_endpoint.network_firewall[each.key].id

#   depends_on = [aws_networkfirewall_firewall.main]
# }
