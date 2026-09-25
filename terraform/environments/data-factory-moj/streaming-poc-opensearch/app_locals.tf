locals {
  name         = "streaming-pov"
  cluster_name = "${local.name}-opensearch"
  # POC resources destroyed but code retained; set back to ["development"] to redeploy
  deploy_to = []

  extended_tags = merge(local.tags, {
    component = local.cluster_name
  })

  opensearch_sg_ingress_cidr = contains(local.deploy_to, local.environment) ? toset([
    for sub in data.aws_subnet.private_subnet_ids : sub.cidr_block
  ]) : toset([])
}
