resource "aws_eip" "nat_gateway" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }

  domain = "vpc"

  tags = {
    Name = "${local.application_name}-${local.environment}-nat-gateway-${each.value.az}"
  }
}
