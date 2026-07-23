locals {
  transfer_subnet_ids = local.is-production ? sort(data.aws_subnets.shared-public.ids) : slice(sort(data.aws_subnets.shared-public.ids), 0, 1)
}