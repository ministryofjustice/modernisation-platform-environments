locals {
  name         = "streaming-pov"
  cluster_name = "${local.name}-opensearch"

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
