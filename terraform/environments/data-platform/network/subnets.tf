resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${data.aws_region.current.region}${each.value.az}"

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.type}-${each.value.az}"
  }
}
