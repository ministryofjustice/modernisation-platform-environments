locals {
  # POC resources destroyed but code retained; set back to ["development"] to redeploy
  deploy_to = []
  extended_tags = merge(local.tags, {
    component = "streaming-pov-opensearch-config"
  })
}
