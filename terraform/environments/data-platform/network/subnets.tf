resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${data.aws_region.current.region}${each.value.az}"

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.type}-${each.value.az}"
  }
}

resource "aws_subnet" "additional" {
  for_each = local.additional_cidr_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${data.aws_region.current.region}${each.value.az}"

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.block_name}-${each.value.type}-${each.value.az}"
  }

  depends_on = [aws_vpc_ipv4_cidr_block_association.additional]
}
