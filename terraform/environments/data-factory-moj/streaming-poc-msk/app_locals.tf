locals {
  name         = "streaming-pov"
  cluster_name = "${local.name}-msk"

  extended_tags = merge(local.tags, {
    component = local.name
  })

  msk_sg_ingress_cidr = contains(["development"], local.environment) ? toset([
    for sub in data.aws_subnet.private_subnet_ids : sub.cidr_block
  ]) : toset([])
}
