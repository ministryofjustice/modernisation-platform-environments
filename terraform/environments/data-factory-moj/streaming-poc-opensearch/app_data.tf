data "aws_subnet" "private_subnet_ids" {
  for_each = contains(local.deploy_to, local.environment) ? toset(data.aws_subnets.shared-private[0].ids) : toset([])
  id       = each.value
}
