# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name      = "streaming-poc-devops"
  deploy_to = ["development"]

  extended_tags = merge(local.tags, {
    component = local.name
  })

  report_schedule = "rate(1 day)"
}
