data "aws_subnets" "shared-protected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-protected*"
  }
}

data "aws_subnet" "shared-protected" {
  for_each = toset(data.aws_subnets.shared-protected.ids)
  id       = each.value
}
