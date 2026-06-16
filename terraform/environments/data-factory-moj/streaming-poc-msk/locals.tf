locals {
  name         = "streaming-pov"
  cluster_name = "${local.name}-msk"

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
