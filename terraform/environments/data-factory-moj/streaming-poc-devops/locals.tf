# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name      = "streaming-poc-devops"
  # POC resources destroyed but code retained; set back to ["development"] to redeploy
  deploy_to = []

  extended_tags = merge(local.tags, {
    component = local.name
  })

  report_schedule = "rate(1 day)"
}
