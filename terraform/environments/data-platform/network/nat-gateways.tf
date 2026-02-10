resource "aws_nat_gateway" "main" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }

  allocation_id = aws_eip.nat_gateway[each.key].id
  subnet_id     = aws_subnet.main["public-${each.key}"].id

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}
