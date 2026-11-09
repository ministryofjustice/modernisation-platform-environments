data "aws_subnet" "private_subnet_ids" {
  for_each = toset(data.aws_subnets.shared-private.ids)
  id       = each.value
}
