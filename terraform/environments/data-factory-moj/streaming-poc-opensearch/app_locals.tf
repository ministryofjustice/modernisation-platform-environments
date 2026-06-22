locals {
  name         = "streaming-pov"
  cluster_name = "${local.name}-opensearch"

  extended_tags = merge(local.tags, {
    component = local.cluster_name
  })

  opensearch_sg_ingress_cidr = contains(["development"], local.environment) ? toset([
    for sub in data.aws_subnet.private_subnet_ids : sub.cidr_block
  ]) : toset([])

  all_vars    = jsondecode(file("${path.cwd}/../application_variables.json"))
  os_mappings = try(local.all_vars.accounts[local.environment].opensearch_role_mappings, {})
}
