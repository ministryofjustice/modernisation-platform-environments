locals {
  name         = "integration-hub-events"
  cluster_name = "${local.name}-msk"
  deploy_to    = ["development"]

  extended_tags = merge(local.tags, {
    component = local.cluster_name
  })

  msk_sg_ingress_cidr = contains(local.deploy_to, local.environment) ? toset([
    for sub in data.aws_subnet.private_subnet_ids : sub.cidr_block
  ]) : toset([])
}
