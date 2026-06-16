# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name              = "streaming-pov"
  ecs_prefix        = "${local.name}-ecs"
  sdg_prefix        = "${local.ecs_prefix}-sdg"
  alerts_prefix     = "${local.ecs_prefix}-alerts"
  deploy_to         = ["development"]
  capacity_provider = contains(["development"], local.environment) ? "FARGATE_SPOT" : null

  ecr_repositories = {
    sdg    = "${local.name}-sdg"
    alerts = "${local.name}-alerts"
  }

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
