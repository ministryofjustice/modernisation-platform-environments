resource "aws_route" "this" {
  for_each = toset(var.destination_cidr_blocks)

  route_table_id         = var.route_table_id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id
}
