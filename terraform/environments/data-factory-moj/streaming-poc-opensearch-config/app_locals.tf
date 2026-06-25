locals {
  deploy_to = ["development"]
  extended_tags = merge(local.tags, {
    component = "streaming-pov-opensearch-config"
  })
}
