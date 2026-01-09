resource "aws_route_table" "main" {
  for_each = local.subnets

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.type}-${each.value.az}"
  }
}

resource "aws_route_table_association" "main" {
  for_each = local.subnets

  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main[each.key].id
}
